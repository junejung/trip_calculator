class Address
  TABLE_NAME  = :addresses

  # In a future version we can extract these dynamically from the SQLite database
  # by executing DB.execute("PRAGMA table_info(addresses)")
  #
  # See: http://www.sqlite.org/pragma.html
  PRIMARY_KEY = :id  
  ATTRIBUTES  = [PRIMARY_KEY, :content, :created_at, :updated_at]

  class << self
    def find(id)
      if row = DB.get_first_row("SELECT * FROM #{TABLE_NAME} WHERE #{PRIMARY_KEY} = ?", id)
        self.new(row)
      else
        raise DB::RecordNotFound.new("No #{self.name} record with id '#{id}'")
      end
    end

    def all
      DB.execute("SELECT * FROM #{TABLE_NAME}").map do |row|
        self.new(row)
      end
    end

    def count
      DB.get_first_value("SELECT COUNT(*) FROM #{TABLE_NAME}")
    end

    def create(opts = {})
      self.new(opts).tap do |record|
        record.save
      end
    end
  end

  # We're not going to store every part of an address
  # Why not?  Will our client need it in the first version?
  # Will they ever need it?
  #
  # I'd guess that someone frequently re-uses < 5 core addresses
  # and every other address is used once

  def initialize(opts = {})
    @attributes = ATTRIBUTES

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

    # Records created via #initialize are new (unsaved) records
    @new_record = @data[PRIMARY_KEY].nil?
  end

  # This allows us to do things like
  # address = Address.new(...)
  # address[:id]
  # address[:content]
  # etc.
  def [](field)
    @data[field.to_sym]
  end

  def update_attribute(field, value)
    if has_attribute?(field)
      @changed = true
      @data[field.to_sym] = value
    else
      raise DB::UnknownAttribute.new("Unknown attribute `#{field}` for class #{self.class}")
    end
  end

  ATTRIBUTES.each do |attribute|
    # define_methods takes as its input a symbol or string and a block
    # and dynamically defines a method with that name and code
    # e.g., these are equivalent:
    # def add(a,b)
    #   a + b
    # end
    #
    # define_method(:add) do |a,b|
    #   a + b
    # end
    #
    # This allows us to define methods at run-time
    define_method(attribute) do
      self[attribute]
    end

    define_method("#{attribute}=") do |value|
      self.update_attribute(attribute, value)
    end
  end

  def has_attribute?(field)
    @attributes.include?(field.to_sym)
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

  def ==(other_address)
    self[PRIMARY_KEY] == other_address[PRIMARY_KEY]
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
    @attributes - Array(PRIMARY_KEY)
  end

  def update
    self.update_attribute(:updated_at, Time.now.utc) if has_attribute?(:updated_at)

    fields = secondary_attributes
    values = secondary_attributes.map { |attr| DB.sanitize(self[attr]) }
    
    update_clause = fields.map { |field| "#{field} = ?"}.join(', ')

    sql = "UPDATE #{TABLE_NAME} SET #{update_clause} WHERE #{PRIMARY_KEY} = ?"
    DB.execute(sql, *values, self[PRIMARY_KEY]).tap do
      @changed = false
    end
  end

  def create
    time = DateTime.now
    self.update_attribute(:created_at, time) if has_attribute?(:created_at)
    self.update_attribute(:updated_at, time) if has_attribute?(:updated_at)

    fields = secondary_attributes
    values = secondary_attributes.map { |attr| DB.sanitize(self[attr]) }

    sql = "INSERT INTO #{TABLE_NAME} (#{fields.join(', ')}) VALUES (#{Array.new(values.length, '?').join(', ')})"
    DB.execute(sql, *values)

    update_attribute(PRIMARY_KEY, DB.last_insert_row_id)

    @new_record = false
    @changed    = false

    self[PRIMARY_KEY]
  end
end