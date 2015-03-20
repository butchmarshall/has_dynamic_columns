has_dynamic_columns
============

Add dynamic columns to ActiveRecord models

Installation
============

```ruby
gem 'has_dynamic_columns'
```

The Active Record migration is required to create the has_dynamic_columns table. You can create that table by
running the following command:

    rails generate has_dynamic_columns:active_record
    rake db:migrate

Usage
============

```ruby
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
	has_dynamic_columns field_scope: "customer.account"
end
```

