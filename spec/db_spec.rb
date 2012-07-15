require './db'
require 'rspec'

describe DB do
  before(:all) do
    DB.reset!
  end

  describe ".database_file=" do
    it "requires the name of a database file" do
      expect {
        DB.send(:database_file=)
      }.to raise_error(ArgumentError)
    end    
  end
  
  describe ".execute" do
    context "with no database file" do
      it "raises a DatabaseError" do
        
        expect {
          DB.execute
        }.to raise_error(DB::ConnectionError)
      end
    end

    context "with a database file" do
      let(:database_file) { "./db/dummy.db" }

      # The benefit of using let(...) { ... } vs. instance variables
      # and before(:each) { ... } is that the blocks are only called 
      # when they're used, whereas you'll execute everything in the 
      # before(:each) section every time, even if you don't need it
      #
      # It's also a clean way to separate the declaration of variables
      # from setting up the environment

      let(:create_sql) { "CREATE TABLE foo (id INTEGER PRIMARY KEY)" }
      let(:insert_sql) { "INSERT INTO foo (id) VALUES (100)" }
      let(:select_sql) { "SELECT * FROM foo" }
      
      let(:select_results) { [{'id' => 100}] }

      before(:each) do
        DB.database_file = database_file
      end
      
      after(:each) do
        # See http://www.ruby-doc.org/core-1.9.3/File.html#method-c-delete
        File.delete(database_file)
      end
      
      # See https://www.relishapp.com/rspec/rspec-expectations/v/2-0/docs/matchers/expect-error
      # for an example of expect { ... }
      # 
      # You can also use lambda { ... } instead of expect { ... }, 
      # but since RSpec 2.0 expect { ... } is preferred
      #
      # See also http://bit.ly/rspec_expect

      it "can create a table" do
        expect {
          DB.execute(create_sql)
        }.to_not raise_error
      end

      it "can insert data" do
        DB.execute(create_sql)

        expect {
          DB.execute(insert_sql)
        }.to_not raise_error
      end
      
      it "returns select data as a hash" do
        DB.execute(create_sql)
        DB.execute(insert_sql)
        
        DB.execute(select_sql).should eq select_results
      end
    end
  end
end