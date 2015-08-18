module HasDynamicColumns
	module ActiveRecord
		module Relation
			def self.included(base)
				base.class_eval do
					attr_accessor :where_dynamic_columns_values, :order_dynamic_columns_values

					# Collect all where clauses
					def where_dynamic_columns_values
						@where_dynamic_columns_values || []
					end
					def where_dynamic_columns_values=values
						raise ImmutableRelation if @loaded
						@where_dynamic_columns_values ||= []
						@where_dynamic_columns_values << values
					end

					# Collect all order clauses
					def order_dynamic_columns_values
						@order_dynamic_columns_values || []
					end
					def order_dynamic_columns_values=values
						raise ImmutableRelation if @loaded
						@order_dynamic_columns_values ||= []
						@order_dynamic_columns_values << values
					end
				end

				base.instance_eval do
				end
			end
		end
	end
end
