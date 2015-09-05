class Upgrade034HasDynamicColumns < ActiveRecord::Migration
	def self.up
		add_column :dynamic_columns, :multiple, :boolean, :default => false
	end

	def self.down
	end
end