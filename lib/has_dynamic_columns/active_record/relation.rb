module HasDynamicColumns
	module ActiveRecord
		module Relation
			def self.included(base)
				base.class_eval do
					def has_dynamic_columns_values
						@values[:has_dynamic_columns_values] || []
					end
					def has_dynamic_columns_values=values
						raise ImmutableRelation if @loaded
						@values[:has_dynamic_columns_values] ||= []
						@values[:has_dynamic_columns_values] << values
					end
				end

				base.instance_eval do
				end
			end
		end
	end
end
