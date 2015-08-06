require 'spec_helper'

describe HasDynamicColumns do
	let (:account) do
		account = Account.new(:name => "Account #1")

		# Setup dynamic fields for Customer under this account
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "email", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "trusted", :data_type => "boolean")

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

		# Product fields
		account.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "rarity", :data_type => "string")

		account
	end

	describe Product do
		subject(:product) {
			Product.new(:name => "Product #1", :account => account)
		}
		before do
			@category0 = Category.new(:name => "Category 0", :account => product.account)
			@category0.save

			@category1 = Category.new(:name => "Category 1", :account => product.account)
			@category1.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "vin_number", :data_type => "string")
			@category1.save

			@category2 = Category.new(:name => "Category 2", :account => product.account)
			@category2.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "serial_number", :data_type => "string")
			@category2.save
			
			@category3 = Category.new(:name => "Category 3", :account => product.account)
			@category3.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "funky_data", :data_type => "string")
			@category3.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "funkier_data", :data_type => "string")
			@category3.save
			
			@category4 = Category.new(:name => "Category 4", :account => product.account)
			@category4.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "funkiest_data", :data_type => "string")
			@category4.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "ok_data", :data_type => "string")
		end

		context 'when it has a defined has_many relationship' do

			context 'when it has_many categories' do

				it 'should return empty category_fields when no categories associated' do
					json = product.as_json
					expect(json["category_fields"]).to eq({})
				end

				it 'should return empty category_fields when no category has no dynamic_columns' do
					product.categories << @category0
					json = product.as_json
					expect(json["category_fields"]).to eq({})
				end

				context 'when not saved' do
					it 'should return a categories fields' do
						product.categories << @category1
						product.category_fields = {
							"vin_number" => "123"
						}

						json = product.as_json
						expect(json["category_fields"]).to eq({"vin_number"=>"123"})
						expect(product.new_record?).to eq(true)
					end
				end
				context 'when saved' do
					it 'should return a categories fields' do
						product.categories << @category1
						product.category_fields = {
							"vin_number" => "345"
						}
						product.save

						json = product.as_json
						expect(json["category_fields"]).to eq({"vin_number"=>"345"})
						expect(product.new_record?).to eq(false)
						
						product_id = product.id
						product = Product.find(product_id)
						json = product.as_json
						expect(json["category_fields"]).to eq({"vin_number"=>"345"})
					end
				end

				it 'should kitchen sink' do
					product.product_fields = {
						"rarity" => "very rare"
					}

					# Add category 1 to the product - it should now have the fields of "vin number"
					product.categories << @category1
					product.categories << @category2

					product.category_fields = {
						"vin_number" => "first:this is the vin number",
						"serial_number" => "first:serial number!"
					}
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"first:serial number!"})

					product.save
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"first:serial number!"})

					product_id = product.id
					product = Product.find(product_id)
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"first:serial number!"})

					product.category_fields = {
						"serial_number" => "second:serial number!"
					}
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"second:serial number!"})

					product.save
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"second:serial number!"})

					product = Product.find(product_id)
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"second:serial number!"})

					expect(@category4.new_record?).to eq(true)

					product.categories << @category3
					product.categories << @category4

					expect(@category4.new_record?).to eq(false)

					product.category_fields = {
						"funkier_data" => "this is funkier data",
						"ok_data" => "this is ok data"
					}
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"second:serial number!", "funky_data"=>nil, "funkier_data"=>"this is funkier data", "funkiest_data"=>nil, "ok_data"=>"this is ok data"})

					product.save
					product = Product.find(product_id)
					json = product.as_json
					expect(json["product_fields"]).to eq({"rarity"=>"very rare"})
					expect(json["category_fields"]).to eq({"vin_number"=>"first:this is the vin number", "serial_number"=>"second:serial number!", "funky_data"=>nil, "funkier_data"=>"this is funkier data", "funkiest_data"=>nil, "ok_data"=>"this is ok data"})
				end
			end
		end
	end

	describe Customer do
		subject(:customer) { Customer.new(:account => account) }
		before do
			customer.fields = {
				"first_name" => "Butch",
				"last_name" => "Marshall",
				"email" => "butch.a.marshall@gmail.com",
				"trusted" => true,
			}
		end

		context 'when it is valid' do
			it 'should not find john' do
				c = customer
				c.save
				a = c.account

				expect(a.customers.dynamic_where(a, { first_name: "John" }).length).to eq(0)
			end
			it 'should find me' do
				c = customer
				expect(c.save).to eq(true)
				a = c.account

				expect(a.customers.dynamic_where(a, { first_name: "Butch" }).length).to eq(1)
			end

			it 'should find me with blank value' do
				c = customer
				c.save
				a = c.account

				expect(a.customers.dynamic_where(a, { first_name: "Butch", last_name: "" }).length).to eq(1)
			end

			it 'should find me by first and last name' do
				c = customer
				c.save
				a = c.account

				expect(a.customers.dynamic_where(a, { first_name: "Butch", last_name: "Marshall" }).length).to eq(1)
			end

			it 'should return fields as json' do
				json = customer.as_json(:root => "customer")

				expect(json["customer"]["fields"]).to eq({
					"first_name" => "Butch",
					"last_name" => "Marshall",
					"email" => "butch.a.marshall@gmail.com",
					"trusted" => true,
				})
			end

			it 'should get and set boolean values properly' do
				c = customer

				c.fields = { "trusted" => true }
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>true})
				c.save
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>true})

				c = Customer.find(c.id)
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>true})

				c.fields = { "trusted" => false }
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>false})
				c.save
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>false})

				c = Customer.find(c.id)
				expect(c.as_json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>"butch.a.marshall@gmail.com", "trusted"=>false})
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
					json = customer_address.as_json(:root => "customer_address")
					
					expect(json["customer_address"]["fields"]).to eq({
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
					json = customer_address.customer.as_json(:root => "customer")
					
					expect(json["customer"]["fields"]).to eq({
						"first_name" => "Butch",
						"last_name" => "Marshall",
						"email" => "butch.a.marshall@gmail.com",
						"trusted" => true,
					})
				end

				it 'should return fields as json' do
					json = customer_address.as_json(:root => "customer_address")
					expect(json["customer_address"]["fields"]).to eq({
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
					json = customer.as_json(:root => "customer_address")

					expect(json["customer_address"]["fields"]).to eq({
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
