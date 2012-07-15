require './init'
require 'rspec'

describe Address do
  let(:address) { Address.new(:content => '249 Oak St. #1 San Francisco, CA') }

  before(:each) do
    # Delete everything from the address table
    DB.execute("DELETE FROM #{Address::TABLE_NAME}")
    
    # Reset the auto-incrementing ID
    DB.execute("DELETE FROM sqlite_sequence WHERE name='#{Address::TABLE_NAME}'")
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
    end
  end
end