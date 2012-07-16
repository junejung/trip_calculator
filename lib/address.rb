class Address
  # In a future version we can extract these dynamically from the SQLite database
  # by executing DB.execute("PRAGMA table_info(addresses)")
  #
  # See: http://www.sqlite.org/pragma.html
  
  # The table associated with this class
  def self.table_name
    :addresses
  end

  # The primary key for the addresses table
  def self.primary_key
    :id
  end

  # A list of attributes, corresponding to fields in the database
  def self.attributes
    [self.primary_key, :label, :content, :created_at, :updated_at]
  end

  # Returns the +Address+ with +id+ or raises a +DB::RecordNotFound+ exception
  def self.find(id)
    if row = DB.get_first_row("SELECT * FROM #{self.table_name} WHERE #{self.primary_key} = ?", id)
      self.new(row)
    else
      raise DB::RecordNotFound.new("No #{self.name} record with id '#{id}'")
    end
  end

  def self.find_by_label(label)
    if data = DB.get_first_row("SELECT * FROM #{self.table_name} WHERE label = ?", label)
      self.new(data)
    end
  end

  # Returns an array of every +Address+ in the database
  def self.all
    DB.execute("SELECT * FROM #{self.table_name}").map do |row|
      self.new(row)
    end
  end

  def self.count
    DB.get_first_value("SELECT COUNT(*) FROM #{self.table_name}")
  end

  def self.create(opts = {})
    record = self.new(opts)
    record.save
    record
  end

  # We're not going to store every part of an address
  # Why not?  Will our client need it in the first version?
  # Will they ever need it?
  #
  # I'd guess that someone frequently re-uses < 5 core addresses
  # and every other address is used once

  def initialize(opts = {})
    @attributes = Address.attributes

    # @data is now, e.g., {:id => 5, :content => '249 Oak St #1 San Francisco, CA'}
    # See http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-update
    # for how Hash#update works
    @data   = @attributes.inject({}) do |hash, field|
                # opt might have strings or symbols for keys, but 
                # we want @data to have only symbols for keys
                hash.update field => (opts[field.to_sym] || opts[field.to_s])
              end

    # We keep track of whether this record has been changed or not
    @changed = false

    # Records are "new" 
    @new_record = get_attribute(Address.primary_key).nil?
  end
  
  def to_s
    if label
      "%s (%s)" % [content, label]
    else
      content
    end
  end

  # Everything after this is related to interacting with the database
  # For the most part, it could be pulled out into an abstract "model" class

  # Return the value of the
  def get_attribute(attribute)
    @data[attribute.to_sym]
  end

  def update_attribute(attribute, value)
    if has_attribute?(attribute)
      @changed = true
      @data[attribute.to_sym] = value
    else
      raise DB::UnknownAttribute.new("Unknown attribute `#{attribute}` for class #{self.class}")
    end
  end

  # We could make these instance variables and use
  # attr_reader, attr_accessor, etc.
  #
  # But then when we go to save a row into the database,
  # how do we know what variables to pull in to the query?
  #
  # We'd have to enumerate them again.

  def id
    get_attribute(:id)
  end

  def id=(id)
    update_attribute(:id, id)
  end

  def label
    get_attribute(:label)
  end

  def label=(label)
    update_attribute(:label, label)
  end

  def content
    get_attribute(:content)
  end

  def content=(content)
    update_attribute(:content, content)
  end

  def created_at
    get_attribute(:created_at)
  end

  def created_at=(created_at)
    update_attribute(:created_at, created_at)
  end

  def updated_at
    get_attribute(:updated_at)
  end

  def updated_at=(updated_at)
    update_attribute(:updated_at, updated_at)
  end
  
  # The above is incredibly repetitive, right?
  # Every time you add or remove an attribute, you'd
  # need to add or remove the getters and setters
  #
  # Here's how you'd make it less repetitive.
  # 
  # self.attributes.each do |attribute|
  #     # define_methods takes as its input a symbol or string and a block
  #     # and dynamically defines a method with that name and code
  #     # e.g., these are equivalent:
  #     # def add(a,b)
  #     #   a + b
  #     # end
  #     #
  #     # define_method(:add) do |a,b|
  #     #   a + b
  #     # end
  #     #
  #     # This allows us to define methods at run-time
  #     define_method(attribute) do
  #       get_attribute(attribute)
  #     end
  # 
  #     define_method("#{attribute}=") do |value|
  #       self.update_attribute(attribute, value)
  #     end
  #   end
  
  def has_attribute?(attribute)
    @attributes.include?(attribute.to_sym)
  end

  def changed?
    @changed
  end

  def new_record?
    @new_record || false
  end
  
  def save
    create_or_update
  end

  def ==(other)
    other.is_a?(Address) && get_attribute(Address.primary_key) == get_attribute(Address.primary_key)
  end

  private
  # Creates a new record or updates an existing record
  # Returns true if the operation succeeded
  # and false otherwise
  def create_or_update
    result = new_record? ? create : update
    result != false
  end

  def secondary_attributes
    @attributes - Array(Address.primary_key)
  end

  def update
    # We only need to update if the object has changed
    return unless changed?

    update_attribute(:updated_at, Time.now.utc) if has_attribute?(:updated_at)

    fields = secondary_attributes
    values = secondary_attributes.map { |attr| DB.sanitize get_attribute(attr) }
    
    update_clause = fields.map { |field| "#{field} = ?"}.join(', ')

    sql = "UPDATE #{Address.table_name} SET #{update_clause} WHERE #{Address.primary_key} = ?"

    result = DB.execute(sql, *values, get_attribute(Address.primary_key))
    @changed = false
    result
  end

  def create
    time = DateTime.now
    update_attribute(:created_at, time) if has_attribute?(:created_at)
    update_attribute(:updated_at, time) if has_attribute?(:updated_at)

    fields = secondary_attributes
    values = secondary_attributes.map { |attr| DB.sanitize get_attribute(attr) }

    sql = "INSERT INTO #{Address.table_name} (#{fields.join(', ')}) VALUES (#{Array.new(values.length, '?').join(', ')})"
    DB.execute(sql, *values)

    update_attribute(Address.primary_key, DB.last_insert_row_id)

    @new_record = false
    @changed    = false

    get_attribute(Address.primary_key)
  end
end