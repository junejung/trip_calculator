require 'rspec'
require_relative '../init'

describe Address do
  let(:address)       { Address.new(:content => '249 Oak St. #1 San Francisco, CA') }
  let(:saved_address) { Address.new(:content => 'gork gork gork').tap { |addr| addr.save } }

  before(:each) do
    # Delete everything from the address table
    DB.execute("DELETE FROM #{Address::TABLE_NAME}")
    
    # Reset the auto-incrementing ID
    DB.execute("DELETE FROM sqlite_sequence WHERE name='#{Address::TABLE_NAME}'")
  end

  describe ".count" do
    it "returns 0 when there are no records" do
      Address.count.should be_zero
    end
  end

  describe ".create" do
    it "creates a new record" do
      expect {
        Address.create(:content => 'foo')
      }.to change(Address, :count).by(1)
    end
  end

  describe ".all" do
    it "returns an empty array when there are no records" do
      Address.all.should eq []
    end

    it "returns all addresses" do
      address.save
      Address.all.should eq [address]
    end
  end

  describe ".find" do
    context "with invalid arguments" do
      it "requires a primary key" do
        expect {
          Address.find
        }.to raise_error(ArgumentError)
      end

      it "raises an error with an invalid primary key" do
        expect {
          Address.find('z')
        }.to raise_error(DB::RecordNotFound)
      end
    end
    
    context "with valid arguments" do
      it "returns an Address" do
        address.save
        Address.find(address.id).should be_an_instance_of Address
      end
      
      it "sets new_record? to false" do
        Address.find(saved_address.id).new_record?.should be_false
      end
    end
  end
  
  describe "#new" do
    it "sets new_record? to true" do
      Address.new.new_record?.should be_true
    end

    it "sets changed? to false" do
      Address.new.changed?.should be_false
    end
  end
  
  describe "#save" do
    context "when the record is new" do
      it "inserts a record" do
        expect {
          address.save
        }.to change(Address, :count).by(1)
      end

      it "requires content" do
        expect {
          Address.new.save
        }.to raise_error
      end

      it "sets created_at" do
        expect {
          address.save
        }.to change(address, :created_at).from(nil).to(DateTime)
      end

      it "sets updated_at" do
        expect {
          address.save
        }.to change(address, :created_at).from(nil).to(DateTime)
      end

      it "it sets new_record? to false" do
        expect {
          address.save
        }.to change(address, :new_record?).from(true).to(false)
      end
    end

    context "when the record already exists" do
      it "updates an existing record" do
        address_id = saved_address.id

        address = Address.find(address_id)
        address.content = 'beep'
        address.save

        Address.find(address_id).content.should eq 'beep'
      end
      
      it "updates updated_at" do
        expect {
          address.save
        }.to change(address, :updated_at)
      end
      
      it "doesn't change the primary key" do
        expect {
          saved_address.content = 'mork'
          saved_address.save
        }.to_not change(saved_address, :id)
      end
    end
  end
end