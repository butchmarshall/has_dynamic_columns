require 'spec_helper'

describe HasDynamicColumns do
	let (:account) do
		account = Account.new(:name => "Account #1")

		# Setup dynamic fields for customers under this account
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "address_1", :data_type => "string")
		account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "address_2", :data_type => "string")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "country", :data_type => "list")
		field.dynamic_column_options.build(:key => "canada")
		field.dynamic_column_options.build(:key => "usa")
		field.dynamic_column_options.build(:key => "mexico")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "city", :data_type => "list")
		field.dynamic_column_options.build(:key => "toronto")
		field.dynamic_column_options.build(:key => "alberta")
		field.dynamic_column_options.build(:key => "vancouver")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "province", :data_type => "list")
		field.dynamic_column_options.build(:key => "ontario")
		field.dynamic_column_options.build(:key => "quebec")

		field = account.activerecord_dynamic_columns.build(:dynamic_type => "Customer", :key => "postal_code", :data_type => "string")
		field.dynamic_column_validations.build(:regexp => "^[^$]+$", :error => "blank")
		field.dynamic_column_validations.build(:regexp => "^[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJKLMNPRSTVWXYZ]( )?\\d[ABCEGHJKLMNPRSTVWXYZ]\\d$", :error => "invalid_format")

		account
	end

	describe Customer do
		subject { Customer.new(:account => account) }

		context 'when it is valid' do
			before do
				subject.fields = {
					"address_1" => "555 Bloor Street",
					"country" => "canada",
					"province" => "ontario",
					"city" => "toronto",
					"postal_code" => "H0H0H0",
				}
			end

			it 'should return fields as json' do
				expect(subject.as_json["customer"]["fields"]).to eq({
					"address_1" => "555 Bloor Street",
					"country" => "canada",
					"province" => "ontario",
					"city" => "toronto",
					"postal_code" => "H0H0H0",
				})
			end

			it 'should validate' do
				expect(subject).to be_valid
			end

			it 'should save successfully' do
				sub = subject
				expect(sub.save).to eq(true)
			end

			it 'should should retrieve properly from the database' do
				sub = subject
				sub.save

				customer = Customer.find(sub.id)
				expect(customer.as_json["customer"]["fields"]).to eq({
					"address_1" => "555 Bloor Street",
					"country" => "canada",
					"province" => "ontario",
					"city" => "toronto",
					"postal_code" => "H0H0H0",
				})
			end
		end

		context 'when it is invalid' do
			before do
				subject.fields = {
					"address_1" => "555 Bloor Street",
					"country" => "canadaaaaa",
					"province" => "ontario",
					"city" => "toronto",
					"postal_code" => "H0H0H",
				}
			end

			it 'should not validate' do
				expect(subject).to_not be_valid
			end
		end
	end
end
