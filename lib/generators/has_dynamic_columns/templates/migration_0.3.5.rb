class Upgrade035HasDynamicColumns < ActiveRecord::Migration
	def self.up
		create_table :dynamic_column_model_data do |t|
			t.integer :value_id
			t.string :value_type
			t.timestamps null: false
		end
		add_index(:dynamic_column_model_data, [:value_id,:value_type], name: "index_by_value")
		add_column :dynamic_columns, :class_name, :string
		add_column :dynamic_columns, :column_name, :string
	end

	def self.down
	end
end