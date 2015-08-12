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

	let (:account2) do
		account = Account.new(:name => "Account #2")

		# Setup dynamic fields for Customer under this account
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "first_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "last_name", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "country", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "company", :data_type => "string")

		# Product fields
		account.activerecord_dynamic_columns.build(:dynamic_type => "Product", :key => "rarity", :data_type => "string")

		account
	end

	describe HasDynamicColumns::ActiveRecord, :focus => true  do
		it 'should find everyone in the current account scope' do
			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "Butch",
				"last_name" => "Marshall",
				"email" => "butch.a.marshall@gmail.com",
				"trusted" => true,
			}
			customer.save

			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "John",
				"last_name" => "Paterson",
				"email" => "john.paterson@gmail.com",
				"trusted" => true,
			}
			customer.save

			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "Steve",
				"last_name" => "Paterson",
				"email" => "steve.paterson@gmail.com",
				"trusted" => true,
			}
			customer.save

			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "Carl",
				"last_name" => "Paterson",
				"email" => "carl@communist.com",
				"trusted" => false,
			}
			customer.save

			table = Customer.arel_table

			# 1 communist
			result = Customer.where.has_dynamic_columns(table[:email].matches("%gmail.com")).with_scope(account)
			expect(result.all.length).to eq(3)

			# 2 patersons
			result = Customer.where.has_dynamic_columns(table[:last_name].eq("Paterson")).with_scope(account)
			expect(result.all.length).to eq(3)

			# 1 john paterson
			result = Customer
						.where.has_dynamic_columns(table[:first_name].eq("John")).with_scope(account)
						.where.has_dynamic_columns(table[:last_name].eq("Paterson")).with_scope(account)
			expect(result.all.length).to eq(1)
		end

		it 'should find the single person in this scope' do
			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "Merridyth",
				"last_name" => "Marshall",
				"email" => "merridyth.marshall@gmail.com",
				"trusted" => true,
			}
			customer.save

			result = Customer.where.has_dynamic_columns(Customer.arel_table[:email].matches("%gmail.com")).with_scope(account)
			expect(result.all.length).to eq(1)
		end

		it 'should find all 4 gmail users when no scope passed' do
			result = Customer.where.has_dynamic_columns(Customer.arel_table[:email].matches("%gmail.com")).without_scope
			expect(result.all.length).to eq(4)
		end

		it 'should find anyone with first names Steve or John in account 1\'s scope' do
			customer = Customer.create(:account => account)
			customer.fields = {
				"first_name" => "Steve",
				"last_name" => "Jobs",
				"email" => "steve.jobs@apple.com",
				"trusted" => false,
			}
			customer.save
			
			result = Customer.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve").or(Customer.arel_table[:first_name].eq("John"))).with_scope(Account.find(1))
			expect(result.all.length).to eq(2)
		end

		it 'should find anyone with first names Steve or John in any scope' do
			result = Customer.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve").or(Customer.arel_table[:first_name].eq("John"))).without_scope
			expect(result.all.length).to eq(3)
		end

		it 'should find anyone with first names Steve or John and is trusted in any scope' do
			result = Customer
						.where.has_dynamic_columns(Customer.arel_table[:trusted].eq(true)).without_scope
						.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve").or(Customer.arel_table[:first_name].eq("John"))).without_scope
			expect(result.all.length).to eq(2)
		end

		it 'should find anyone with first names Steve and is not trusted in any scope' do
			result = Customer
						.where.has_dynamic_columns(Customer.arel_table[:trusted].eq(false)).without_scope
						.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve")).without_scope
			expect(result.all.length).to eq(1)
		end
		
		it 'should find all the Steves who are trusted in account 3\'s scope' do
			result = Customer
						.where.has_dynamic_columns(Customer.arel_table[:trusted].eq(true)).with_scope(Account.find(3))
						.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve")).without_scope
			expect(result.all.length).to eq(0)
		end

		it 'should find all the Steves who are trusted in account 1\'s scope' do
			result = Customer
						.where.has_dynamic_columns(Customer.arel_table[:trusted].eq(true)).with_scope(Account.find(1))
						.where.has_dynamic_columns(Customer.arel_table[:first_name].eq("Steve")).without_scope
			expect(result.all.length).to eq(1)
		end

		it 'should find across column types if no scope specified' do
			customer = Customer.create(:account => account2)
			customer.fields = {
				"first_name" => "Steve",
				"last_name" => "Jobs",
				"company" => "Apple Computers",
				"country" => "USA",
			}
			customer.save

			result = Customer
						.where.has_dynamic_columns(
							Customer.arel_table[:first_name].eq("John").or(
								Customer.arel_table[:company].eq("Apple Computers")
							)
						).without_scope
			expect(result.all.length).to eq(2)
		end

		it 'should restrict if scope specified' do
			result = Customer
						.where.has_dynamic_columns(
							Customer.arel_table[:first_name].eq("John").or(
								Customer.arel_table[:company].eq("Apple Computers")
							)
						).with_scope(Account.find(4))
			expect(result.all.length).to eq(1)
		end
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
				it 'should work with dynamic_where' do
					product1 = Product.new(:name => "Product #1", :account => account)
					product2 = Product.new(:name => "Product #2", :account => account)

					# Product 1 is associated with both categories
					product1.categories << @category1
					product1.categories << @category2
					# Product 2 is only associated with a single category
					product2.categories << @category1

					product1.product_fields = {
						"rarity" => "very rare"
					}
					product2.product_fields = {
						"rarity" => "kinda rare"
					}

					product1.category_fields = {
						"vin_number" => "abc",
						"serial_number" => "456"
					}
					product2.category_fields = {
						"vin_number" => "cde",
					}
					product1.save
					product2.save

					result = Product.dynamic_where({ vin_number: "abc" })
					expect(result.length).to eq(1)
					expect(result.first).to eq(product1)

					result = Product.dynamic_where({ vin_number: "cde" })
					expect(result.length).to eq(1)
					expect(result.first).to eq(product2)

					result = Product.dynamic_where({ rarity: "rare" })
					expect(result.length).to eq(2)
					expect(result.first).to eq(product1)
					expect(result.last).to eq(product2)

					result = Product.dynamic_where({ rarity: "rare", vin_number: "cde" })
					expect(result.length).to eq(1)
					expect(result.first).to eq(product2)

					result = Product.dynamic_where({ rarity: "rare", vin_number: "cde", serial_number: "456" })
					expect(result.length).to eq(0)

					result = Product.dynamic_where({ rarity: "rare", vin_number: "c", serial_number: "456" })
					expect(result.length).to eq(1)
				end

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
