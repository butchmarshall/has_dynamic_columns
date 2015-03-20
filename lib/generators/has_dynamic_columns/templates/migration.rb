class HasDynamicColumnsMigration < ActiveRecord::Migration
	def self.up
		create_table :dynamic_columns do |t|
			t.integer :field_scope_id
			t.string :field_scope_type

			t.string :dynamic_type
			t.string :key
			t.string :data_type

			t.timestamps
		end
		create_table :dynamic_column_validations do |t|
			t.integer :dynamic_column_id

			t.string :error
			t.string :regexp

			t.timestamps
		end
		create_table :dynamic_column_options do |t|
			t.integer :dynamic_column_id
			t.string :key

			t.timestamps
		end
		create_table :dynamic_column_data do |t|
			t.string :owner_type
			t.integer :owner_id
			t.integer :dynamic_column_id
			t.integer :dynamic_column_option_id
			t.string :value

			t.timestamps
		end
	end

	def self.down
		drop_table :dynamic_columns
	end
end