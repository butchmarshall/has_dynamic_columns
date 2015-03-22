require 'spec_helper'

describe HasDynamicColumns do
	let (:account) do
		account = Account.new(:name => "Account #1")

		# Setup dynamic fields for Customer under this account
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "email", :data_type => "string")

		# Setup dynamic fields for CustomerAddress under this account
		account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "address_1", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "address_2", :data_type => "string")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "country", :data_type => "list")
		field.dynamic_column_options.build(:key => "canada")
		field.dynamic_column_options.build(:key => "usa")
		field.dynamic_column_options.build(:key => "mexico")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "city", :data_type => "list")
		field.dynamic_column_options.build(:key => "toronto")
		field.dynamic_column_options.build(:key => "alberta")
		field.dynamic_column_options.build(:key => "vancouver")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "province", :data_type => "list")
		field.dynamic_column_options.build(:key => "ontario")
		field.dynamic_column_options.build(:key => "quebec")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "CustomerAddress", :key => "postal_code", :data_type => "string")
		field.dynamic_column_validations.build(:regexp => "^[^$]+$", :error => "blank")
		field.dynamic_column_validations.build(:regexp => "^[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJKLMNPRSTVWXYZ]( )?\\d[ABCEGHJKLMNPRSTVWXYZ]\\d$", :error => "invalid_format")

		account
	end

	describe Customer do
		subject(:customer) { Customer.new(:account => account) }
		before do
			customer.fields = {
				"first_name" => "Butch",
				"last_name" => "Marshall",
				"email" => "butch.a.marshall@gmail.com",
			}
		end

		context 'when it is valid' do
			it 'should return fields as json' do
				expect(customer.as_json["customer"]["fields"]).to eq({
					"first_name" => "Butch",
					"last_name" => "Marshall",
					"email" => "butch.a.marshall@gmail.com",
				})
			end
		end

		describe CustomerAddress do
			subject(:customer_address) { CustomerAddress.new(:customer => customer) }

			context 'when it has partial data' do
				before do
					customer_address.fields = {
						"country" => "canada",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H0",
					}
				end

				it 'should return nil for unset fields' do
					expect(customer_address.as_json["customer_address"]["fields"]).to eq({
						"address_1" => nil,
						"address_2" => nil,
						"country" => "canada",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H0",
					})
				end
			end

			context 'when it is valid' do
				before do
					customer_address.fields = {
						"address_1" => "555 Bloor Street",
						"country" => "canada",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H0",
					}
				end

				it 'should return parent customer fields as json' do
					expect(customer_address.customer.as_json["customer"]["fields"]).to eq({
						"first_name" => "Butch",
						"last_name" => "Marshall",
						"email" => "butch.a.marshall@gmail.com",
					})
				end

				it 'should return fields as json' do
					expect(customer_address.as_json["customer_address"]["fields"]).to eq({
						"address_1" => "555 Bloor Street",
						"address_2" => nil,
						"country" => "canada",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H0",
					})
				end

				it 'should validate' do
					expect(customer_address).to be_valid
				end

				it 'should save successfully' do
					sub = customer_address
					expect(sub.save).to eq(true)
				end

				it 'should should retrieve properly from the database' do
					sub = customer_address
					sub.save
	
					customer = CustomerAddress.find(sub.id)
					expect(customer.as_json["customer_address"]["fields"]).to eq({
						"address_1" => "555 Bloor Street",
						"address_2" => nil,
						"country" => "canada",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H0",
					})
				end
			end

			context 'when it is invalid' do
				before do
					customer_address.fields = {
						"address_1" => "555 Bloor Street",
						"address_2" => nil,
						"country" => "canadaaaaa",
						"province" => "ontario",
						"city" => "toronto",
						"postal_code" => "H0H0H",
					}
				end

				it 'should not validate' do
					expect(customer_address).to_not be_valid
				end
			end
		end
	end
end
