require 'spec_helper'

describe HasDynamicColumns::DynamicColumnModelDatum do
	let (:account) do
		FactoryGirl.create(:account_with_customer_dynamic_columns)
	end

	context 'Customer' do
		it 'should output json as polymoprhic' do
			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Butch",
				"last_name" => "Marshall",
				"total_purchases" => 123654,
				"trusted" => true,
				"address" => CustomerAddress.new(:name => "1796 18th St, San Francisco, CA 94107, United States"),
				"products" => [
					Product.new(:name => "P1"),
					Product.new(:name => "P2"),
					Product.new(:name => "P3"),
					Product.new(:name => "P4"),
					Product.new(:name => "P5"),
				]
			}
			customer.save
			json = customer.as_json(:root => nil)

			expect(json["fields"]["address"]["name"]).to eq("1796 18th St, San Francisco, CA 94107, United States")
			expect(json["fields"]["products"].length).to eq(5)
			# Each of the products should be json
			json["fields"]["products"].each_with_index { |i, index|
				expect(i["name"]).to eq("P#{index+1}")
			}
		end

		it 'should be searchable', :focus => true do
			table = Customer.arel_table

			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Linus",
				"last_name" => "Rorvalds",
				"total_purchases" => 123654,
				"trusted" => true,
				"address" => CustomerAddress.new(:name => "1796 18th St, San Francisco, CA 94107, United States")
			}
			customer.save

			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Bill",
				"last_name" => "Gates",
				"total_purchases" => 123654,
				"trusted" => true,
				"address" => CustomerAddress.new(:name => "15010 NE 36th Street, Redmond, WA 98052, United States")
			}
			customer.save

			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Mark",
				"last_name" => "Zuceberg",
				"total_purchases" => 123654,
				"trusted" => true,
				"address" => CustomerAddress.new(:name => "1 Hacker Way, Menlo Park, CA 94025, United States")
			}
			customer.save

			customer = Customer.new(:account => account)
			customer.fields = {
				"first_name" => "Larry",
				"last_name" => "Page",
				"total_purchases" => 123654,
				"trusted" => true,
				"address" => CustomerAddress.new(:name => "1600 Amphitheatre Pkwy, Mountain View, CA 94043, United States")
			}
			customer.save

			result = Customer
				.where
					.has_dynamic_columns(table[:address].matches("%United States%"))
					.with_scope(account)
			expect(result.length).to eq(4)

			result = Customer
				.where
					.has_dynamic_columns(table[:address].matches("% CA %"))
					.with_scope(account)
			expect(result.length).to eq(3)

			result = Customer
				.where
					.has_dynamic_columns(
						table[:address].matches("% Hacker %").or(
							table[:address].matches("1600 %")
						)
					)
					.with_scope(account)
			expect(result.length).to eq(2)

			result = Customer
				.where
					.has_dynamic_columns(
						table[:address].matches("% Hacker %").or(
							table[:first_name].eq("Larry")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(
						last_name: :asc
					)
					.with_scope(account)
			expect(result.length).to eq(2)
			expect(result.first.as_json["fields"]["address"]["name"]).to eq("1600 Amphitheatre Pkwy, Mountain View, CA 94043, United States")
		end
	end
end