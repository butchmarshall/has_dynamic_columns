require 'logger'
require 'rspec'
require 'factory_girl'

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

if RUBY_PLATFORM == 'java'
	ActiveRecord::Base.establish_connection :adapter => 'jdbcsqlite3', :database => ':memory:'
else
	ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
end

ActiveRecord::Migration.verbose = false

require "generators/has_dynamic_columns/templates/migration"
require "generators/has_dynamic_columns/templates/migration_0.3.0"
require "generators/has_dynamic_columns/templates/migration_0.3.4"
require "generators/has_dynamic_columns/templates/migration_0.3.5"
ActiveRecord::Schema.define do
	AddHasDynamicColumns.up
	Upgrade030HasDynamicColumns.up
	Upgrade034HasDynamicColumns.up
	Upgrade035HasDynamicColumns.up

	create_table :accounts, force: true do |t|
		t.string :name
		t.timestamps null: false
	end
	create_table :customers, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps null: false
	end
	create_table :customer_addresses, force: true do |t|
		t.string :name
		t.integer :customer_id
		t.timestamps null: false
	end
	create_table :products, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps null: false
	end
	create_table :categories, force: true do |t|
		t.string :name
		t.integer :account_id
		t.timestamps null: false
	end
	create_table :category_owners, force: true do |t|
		t.integer :category_id
		t.integer :owner_id
		t.string :owner_type
		t.timestamps null: false
	end
end

class Account < ActiveRecord::Base
	has_many :customers
	has_dynamic_columns
end

class Customer < ActiveRecord::Base
	belongs_to :account
	has_many :customer_addresses
	has_dynamic_columns field_scope: "account", as: "fields"
end

class CustomerAddress < ActiveRecord::Base
	belongs_to :customer
	has_dynamic_columns field_scope: "customer.account", as: "fields"
end

class Product < ActiveRecord::Base
	belongs_to :account
	has_many :category_owners, :as => :owner
	has_many :categories, :through => :category_owners

	# Fields defined via the account
	has_dynamic_columns field_scope: "account", as: "product_fields"

	# Fields defined via any associated categories
	has_dynamic_columns field_scope: "categories", as: "category_fields"
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

require_relative '../spec/factories/account'
require_relative '../spec/factories/customer'

RSpec.configure do |config|
	config.include FactoryGirl::Syntax::Methods
	config.after(:each) do
	end
	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
