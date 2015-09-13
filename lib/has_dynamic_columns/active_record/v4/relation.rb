ActiveRecord::VERSION::MAJOR

module HasDynamicColumns
	module ActiveRecord
		module Relation
			def self.included(base)
				base.class_eval do
					# Collect all where clauses
					def joins_dynamic_columns
						@values[:joins_dynamic_columns] = @values[:joins_dynamic_columns] || {}
						@values[:joins_dynamic_columns]
					end

					# Collect all where clauses
					def where_dynamic_columns_values
						@values[:where_dynamic_columns_values] || []
					end
					def where_dynamic_columns_values=values
						raise ImmutableRelation if @loaded
						@values[:where_dynamic_columns_values] ||= []
						@values[:where_dynamic_columns_values] << values
					end

					# Collect all order clauses
					def order_dynamic_columns_values
						@values[:order_dynamic_columns_values] || []
					end
					def order_dynamic_columns_values=values
						raise ImmutableRelation if @loaded
						@values[:order_dynamic_columns_values] ||= []
						@values[:order_dynamic_columns_values] << values
					end
				end

				base.instance_eval do
				end
			end
		end
	end
end
