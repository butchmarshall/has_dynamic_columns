require 'logger'
require 'rspec'

require 'active_support/dependencies'
require 'active_record'

require 'has_dynamic_columns'

if ENV['DEBUG_LOGS']
	
else

end
ENV['RAILS_ENV'] = 'test'

# Trigger AR to initialize
ActiveRecord::Base

module Rails
  def self.root
    '.'
  end
end

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)

# Used to test interactions between DJ and an ORM
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
ActiveRecord::Migration.verbose = false

require "generators/has_dynamic_columns/templates/migration"
ActiveRecord::Schema.define do
	HasDynamicColumnsMigration.up

	create_table :accounts, force: true do |t|
		t.string :name
		t.timestamps
	end
	create_table :customers, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps
	end
	create_table :customer_addresses, force: true do |t|
		t.string :name
		t.integer :customer_id
		t.timestamps
	end
end

class Account < ActiveRecord::Base
	has_many :customers
	has_dynamic_columns
end

class Customer < ActiveRecord::Base
	belongs_to :account
	has_many :customer_addresses
	has_dynamic_columns field_scope: "account", dynamic_type: "Address", as: "fields"
end

class CustomerAddress < ActiveRecord::Base
	belongs_to :customer
	has_dynamic_columns field_scope: "customer.account"
end


RSpec.configure do |config|
	config.after(:each) do
		
	end

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
