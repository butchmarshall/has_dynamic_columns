FactoryGirl.define do
	factory :customer do |f|
		initialize_with {
			Customer.new(account: account)
		}

		f.name "Customer"
	end

	factory :customer_with_dynamic_column_data, parent: :customer do |f|
		transient do
			index 0
		end

		before(:create, :build) do |customer, evaluator|
			hash = {}
			customer.account.activerecord_dynamic_columns.each_with_index { |i,index|
				hash[i.key.to_s] = case i.data_type
				when 'integer'
					evaluator.index
				when 'datetime'
					DateTime.now.change(hour: evaluator.index)
				when 'boolean'
					true
				when 'model'
					nil
				else
					"#{evaluator.index } - #{i.data_type}"
				end

				hash[i.key.to_s] = [hash[i.key.to_s]]if i.multiple
			}
			customer.fields = hash

			customer
		end
	end

end