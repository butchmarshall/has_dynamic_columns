FactoryGirl.define do
	factory :account do |f|
		f.name "Account Name Here"
	end

	factory :account_with_customer_dynamic_columns, parent: :account do
		before(:create, :build) do |account|
			# Setup dynamic fields for Customer under this account
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "email", :data_type => "string")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "trusted", :data_type => "boolean")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_contacted", :data_type => "datetime")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "total_purchases", :data_type => "integer")
			account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "tags", :data_type => "string", :multiple => true)
		end
	end

	factory :account_with_product_dynamic_columns, parent: :account do
		before(:create, :build) do |account|
			# Product fields
			account.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "rarity", :data_type => "string")
		end
	end
end