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
	AddHasDynamicColumns.up

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
	create_table :products, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps
	end
	create_table :categories, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps
	end
	create_table :category_owners, force: true do |t|
		t.integer :category_id
		t.integer :owner_id
		t.string :owner_type
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
	has_dynamic_columns field_scope: "account", dynamic_type: "Customer", as: "fields"
end

class CustomerAddress < ActiveRecord::Base
	belongs_to :customer
	has_dynamic_columns field_scope: "customer.account", dynamic_type: "CustomerAddress", as: "fields"
end

class Product < ActiveRecord::Base
	belongs_to :account
	has_many :category_owners, :as => :owner
	has_many :categories, :through => :category_owners

	# Fields defined via the account
	has_dynamic_columns field_scope: "account", dynamic_type: "Product", as: "product_fields"

	# Fields defined via any associated categories
	has_dynamic_columns field_scope: "categories", dynamic_type: "Product", as: "category_fields"
end

class Category < ActiveRecord::Base
	belongs_to :account
	has_many :category_owners

	has_dynamic_columns field_scope: "account"
end

class CategoryOwner < ActiveRecord::Base
	belongs_to :category
	belongs_to :owner, :polymorphic => true
end

RSpec.configure do |config|
	config.after(:each) do
		
	end

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
