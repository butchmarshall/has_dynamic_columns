class Upgrade030HasDynamicColumns < ActiveRecord::Migration
	def self.up
		add_column :dynamic_column_data, :datum_type, :string
		add_column :dynamic_column_data, :datum_id, :integer

		create_table :dynamic_column_boolean_data do |t|
			t.boolean :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_boolean_data, [:value])

		create_table :dynamic_column_date_data do |t|
			t.date :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_date_data, [:value])

		create_table :dynamic_column_datetime_data do |t|
			t.datetime :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_datetime_data, [:value])

		create_table :dynamic_column_enum_data do |t|
			t.string :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_enum_data, [:value])

		create_table :dynamic_column_float_data do |t|
			t.float :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_float_data, [:value])

		create_table :dynamic_column_integer_data do |t|
			t.integer :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_integer_data, [:value])

		create_table :dynamic_column_string_data do |t|
			t.string :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_string_data, [:value])

		create_table :dynamic_column_text_data do |t|
			t.text :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_text_data, [:value], :length => 255)

		create_table :dynamic_column_time_data do |t|
			t.time :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_time_data, [:value])

		create_table :dynamic_column_timestamp_data do |t|
			t.timestamp :value
			t.timestamps null: false
		end
		add_index(:dynamic_column_timestamp_data, [:value])

		# Migrate data
		["string","integer","boolean","text"].each { |data_type|
			ActiveRecord::Base.connection.select_all("
			SELECT
				`dynamic_column_data`.*
			FROM `dynamic_columns`
				INNER JOIN `dynamic_column_data`
					ON `dynamic_column_data`.`dynamic_column_id` = `dynamic_columns`.`id`
			WHERE `dynamic_columns`.`data_type` = '#{data_type}'
			").each { |i|
				obj = "::HasDynamicColumns::DynamicColumn#{data_type.camelize}Datum".constantize.create(:value => i["value"])
				if datum = ::HasDynamicColumns::DynamicColumnDatum.where(:id => i["id"]).first
					datum.datum = obj
					datum.save
				end
			}
		}

		remove_column :dynamic_column_data, :value
	end

	def self.down
	end
end
