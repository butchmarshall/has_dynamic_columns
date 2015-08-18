require 'spec_helper'

describe HasDynamicColumns::DynamicColumnIntegerDatum do
	let (:account) do
		FactoryGirl.create(:account_with_customer_dynamic_columns)
	end

	context 'Customer' do
		it 'should output json as integer' do
			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Butch",
				"last_name" => "Marshall",
				"total_purchases" => 123654,
				"trusted" => true,
			}
			customer.save
			json = customer.as_json(:root => nil)
			expect(json["fields"]).to eq({"first_name"=>"Butch", "last_name"=>"Marshall", "email"=>nil, "trusted"=>true, "last_contacted"=>nil, "total_purchases"=>123654})
		end

		context 'where.has_dynamic_columns' do
			before do
				(0..1).each { |k|
					(0..10).each { |i|
						customer = Customer.new(:account => account)
						customer.fields = {
							"first_name" => "Butch",
							"last_name" => "Marshall",
							"total_purchases" => i,
							"trusted" => (i%2 == 0),
						}
						customer.save
					}
				}
			end

			it 'should find using hash' do
				expect(account.customers.length).to eq(22)
	
				result = Customer
					.where
						.has_dynamic_columns(total_purchases: 5)
						.with_scope(account)
	
				expect(result.length).to eq(2)
			end
			it 'should find all customers with less than 5 purchases' do
				table = Customer.arel_table
				expect(account.customers.length).to eq(22)
	
				result = Customer
					.where
						.has_dynamic_columns(
							table[:total_purchases].lt(5)
						)
						.with_scope(account)
	
				expect(result.length).to eq(10)
			end
			it 'should find all customers with greater than 5 purchases' do
				table = Customer.arel_table
				expect(account.customers.length).to eq(22)
	
				result = Customer
					.where
						.has_dynamic_columns(
							table[:total_purchases].gt(5)
						)
						.with_scope(account)
	
				expect(result.length).to eq(10)
			end
			it 'should find all customers with less than 7 purchases but more than 3' do
				table = Customer.arel_table
				expect(account.customers.length).to eq(22)
	
				result = Customer
					.where
						.has_dynamic_columns(
							table[:total_purchases].lt(7).and(
								table[:total_purchases].gt(3)
							)
						)
						.with_scope(account)
	
				expect(result.length).to eq(6)
			end
		end
		it 'should kitchen sink' do
			table = Customer.arel_table
			first_names =  ['Allison', 'Arthur', 'Ana', 'Beryl', 'Chantal', 'Cristobal', 'Claudette']
			last_names = ['Abbott', 'Acevedo', 'Anderson', 'Andrews', 'Anthony', 'Armstrong']

			customers = []
			(0..first_names.length).each { |j|
				(0..last_names.length).each { |k|
					customers << [{
						:account => account,
						:fields => {
						"first_name" => first_names[j%first_names.length],
						"last_name" => last_names[k%last_names.length],
						"total_purchases" => j+k,
						"trusted" => (k%2 == 0),
					}
					}]
				}
			}

			Customer.create(customers)
			result = Customer
					.where
					.has_dynamic_columns(
						table[:first_name].matches("A%").and(
							table[:trusted].eq(true)
						).or(
							table[:last_name].eq("Armstrong")
						)
					)
					.with_scope(account)
			expect(result.length).to eq(24)
		end
	end
end