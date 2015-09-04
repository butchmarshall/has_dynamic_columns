require 'spec_helper'

describe ::HasDynamicColumns::ActiveRecord::QueryMethods do
	let (:account) do
		FactoryGirl.create(:account_with_customer_dynamic_columns)
	end

	before do
		(1..10).each { |i|
			FactoryGirl.create(:customer_with_dynamic_column_data, account: account, index: i)
		}
		customer = Customer.new(:account => account, :name => "2")
		customer.fields = {
			"first_name" => "Butch",
			"last_name" => "Marshall",
			"email" => "butch.a.marshall@unittest.com",
			"trusted" => true,
			"last_contacted" => DateTime.parse("2015-01-01 01:01:01"),
			"total_purchases" => 30
		}
		customer.save

		customer = Customer.new(:account => account, :name => "1")
		customer.fields = {
			"first_name" => "Butch",
			"last_name" => "Casidy",
			"email" => "butch.marshall@unittest.com",
			"trusted" => true,
			"last_contacted" => DateTime.parse("2011-01-01 01:01:01"),
			"total_purchases" => 30
		}
		customer.save

		customer = Customer.new(:account => account, :name => "1")
		customer.fields = {
			"first_name" => "George",
			"last_name" => "Marshall",
			"email" => "george.marshall@unittest.com",
			"trusted" => false,
			"last_contacted" => DateTime.parse("2014-01-01 01:01:01"),
			"total_purchases" => 10
		}
		customer.save
	end

	context 'Customer' do
		it 'should order by first_name' do
			table = Customer.arel_table

			result = Customer
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["2", "Butch", "Marshall"], ["1", "Butch", "Casidy"], ["Customer", "9 - string", "9 - string"], ["Customer", "8 - string", "8 - string"], ["Customer", "7 - string", "7 - string"], ["Customer", "6 - string", "6 - string"], ["Customer", "5 - string", "5 - string"], ["Customer", "4 - string", "4 - string"], ["Customer", "3 - string", "3 - string"], ["Customer", "2 - string", "2 - string"], ["Customer", "10 - string", "10 - string"], ["Customer", "1 - string", "1 - string"]])
		end

		it 'should order by first_name and filter' do
			table = Customer.arel_table

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["2", "Butch", "Marshall"], ["1", "Butch", "Casidy"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(first_name: :asc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["2", "Butch", "Marshall"], ["1", "Butch", "Casidy"], ["1", "George", "Marshall"]])
		end

		it 'should order by dynamic and regular columns', :focus => true do
			table = Customer.arel_table

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.order('"customers"."name" DESC')

			result = result.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["2", "Butch", "Marshall"], ["1", "Butch", "Casidy"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.order('"customers"."name" ASC')
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["1", "Butch", "Casidy"], ["2", "Butch", "Marshall"]])
		end

		it 'should preserve order precedence' do
			table = Customer.arel_table

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order('"customers"."name" ASC')
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["1", "Butch", "Casidy"], ["2", "Butch", "Marshall"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(first_name: :desc)
					.with_scope(account)
				.order('"customers"."name" ASC')
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["1", "Butch", "Casidy"], ["2", "Butch", "Marshall"]])
		end

		it 'should preserve order by multiple dynamic columns' do
			table = Customer.arel_table

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(last_name: :desc, first_name: :desc)
					.with_scope(account)
				.order('"customers"."name" ASC')
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", "George", "Marshall"], ["2", "Butch", "Marshall"], ["1", "Butch", "Casidy"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(last_name: :desc, first_name: :asc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["2", "Butch", "Marshall"], ["1", "George", "Marshall"], ["1", "Butch", "Casidy"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(total_purchases: :desc, last_name: :desc, first_name: :asc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["total_purchases"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["2", 30, "Butch", "Marshall"], ["1", 30, "Butch", "Casidy"], ["1", 10, "George", "Marshall"]])

			result = Customer
				.where
					.has_dynamic_columns(
						table[:first_name].eq("Butch").or(
							table[:first_name].eq("George")
						)
					)
					.with_scope(account)
				.order
					.by_dynamic_columns(total_purchases: :desc, last_name: :asc, first_name: :asc)
					.with_scope(account)
				.collect { |i|
				json = i.as_json(:root => nil)
				[json["name"], json["fields"]["total_purchases"], json["fields"]["first_name"], json["fields"]["last_name"]]
			}
			expect(result).to eq([["1", 30, "Butch", "Casidy"], ["2", 30, "Butch", "Marshall"], ["1", 10, "George", "Marshall"]])
		end
	end

	context 'ActiveRecord' do
		it 'should not clobber where IN queries' do
			sql = Account.where("id IN (?)", [1,2,3]).to_sql
			expect(sql).to eq('SELECT "accounts".* FROM "accounts" WHERE (id IN (1,2,3))')
		end
	end

end