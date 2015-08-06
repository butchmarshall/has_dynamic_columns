has_dynamic_columns
============

This plugin gives ActiveRecord models the ability to dynamically define collectable data based on ***has_many*** and ***belongs_to*** relationships.

Installation
============

```ruby
gem "has_dynamic_columns"
```

The Active Record migration is required to create the has_dynamic_columns table. You can create that table by
running the following command:

    rails generate has_dynamic_columns:active_record
    rake db:migrate

Usage
============

has_dynamic_columns

 - as: 
	 - the setter/getter method
 - field_scope:
	 - **belongs_to** or **has_many** relationship 

## **belongs_to** relationship

Our example is a data model where an **account** ***has_many*** **customers** and each **customer** ***has_many*** **customer_addresses**

Each customers collectable info is uniquely defined by the associated account.

Each customer addresses collectable info is defined by the associated customers account.

**Models**
```ruby
class Account < ActiveRecord::Base
	has_many :customers
	has_dynamic_columns
end

class Customer < ActiveRecord::Base
	belongs_to :account
	has_dynamic_columns field_scope: "account", as: "customer_fields"
end

class CustomerAddress < ActiveRecord::Base
	belongs_to :customer
	has_dynamic_columns field_scope: "customer.account"
end
```

**Setup**
```ruby
# ------------------------------------------------
# Create our first account
# ------------------------------------------------
account = Account.new(:name => "Account #1")

# Define a first_name field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
# Define a last_name field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
# Define a company field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "company", :data_type => "string")

# save
account.save

# ------------------------------------------------
# Create our second account
# ------------------------------------------------
account = Account.new(:name => "Account #2")

# Define a first_name field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
# Define a last_name field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
# Define a country field
account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "country", :data_type => "string")

# save
account.save
```

**Data**
```ruby
# Add a customer to our first account
account = Account.find(1)
customer = Customer.new(:account => account)
customer.customer_fields = {
	"first_name" => "Butch",
	"last_Name" => "Marshall",
	"company" => "Aperture Science"
}
customer.save

# as_json
customer.as_json
# == { "id": 1, "account_id": 1, "customer_fields" => { "first_name" => "Butch", "last_Name" => "Marshall", "company" => "Aperture Science" } }

# Add a customer to our first account
account = Account.find(1)
customer = Customer.new(:account => account)
customer.customer_fields = {
	"first_name" => "John",
	"last_Name" => "Paterson",
	"company" => "Aperture Science"
}
customer.save

# Add a customer to our second account
account = Account.find(2)
customer = Customer.new(:account => account)
customer.customer_fields = {
	"first_name" => "Butch",
	"last_Name" => "Marshall",
	"country" => "Canada"
}
customer.save

# as_json
puts customer.as_json
# == { "id": 2, "account_id": 2, "customer_fields" => { "first_name" => "Butch", "last_Name" => "Marshall", "country" => "Canada" } }
```

**Searching**
```ruby
# ------------------------------------------------
# Find customers under the first account
# ------------------------------------------------
account = Account.find(1)

# 1 result
Customer.dynamic_where(account, { :first_name => "Butch" })

# 1 result
Customer.dynamic_where(account, { :first_name => "Butch", :company => "Aperture Science" })

# 0 results
Customer.dynamic_where(account, { :first_name => "Butch", :company => "Blaaaaa" })

# 2 results
Customer.dynamic_where(account, { :company => "Aperture Science" })


# ------------------------------------------------
# Find customers under the second account
# ------------------------------------------------
account = Account.find(2)
# 1 result
Customer.dynamic_where(account, { :first_name => "Butch" })

# 1 result
Customer.dynamic_where(account, { :first_name => "Butch", :country => "Canada" })

# 0 results
Customer.dynamic_where(account, { :first_name => "Butch", :country => "Japan" })
```

## **has_many** relationship

TODO example.