module HasDynamicColumns
	class DynamicColumnDatum < ActiveRecord::Base
		belongs_to :dynamic_column, :class_name => "HasDynamicColumns::DynamicColumn"
		belongs_to :dynamic_column_option, :class_name => "HasDynamicColumns::DynamicColumnOption"
		belongs_to :owner, :polymorphic => true

		# Get value based on dynamic_column data_type
		def value
			if self.dynamic_column
				case self.dynamic_column.data_type
					when "list"
						if self.dynamic_column_option
							self.dynamic_column_option.key
						end
					when "datetime"
						self[:value]
					when "boolean"

						if self[:value].is_a?(TrueClass) || self[:value].is_a?(FalseClass)
							self[:value]
						else
							self[:value].to_i === 1
						end
					when "integer"
						self[:value]
					when "date"
						self[:value]
					when "string"
						self[:value]
				end
			else
				self[:value]
			end
		end

		# Set value base don dynamic_column data_type
		def value=v
			if self.dynamic_column
				case self.dynamic_column.data_type
					when "list"
						# Can only set the value to one of the option values
						if option = self.dynamic_column.dynamic_column_options.select { |i| i.key == v }.first
							self.dynamic_column_option = option
						else
							# Hacky, -1 indicates to the validator that an invalid option was set
							self.dynamic_column_option = nil
							self.dynamic_column_option_id = (v.to_s.length > 0)? -1 : nil
						end
					when "datetime"
						self[:value] = v
					when "boolean"
						self[:value] = (v)? 1 : 0
					when "integer"
						self[:value] = v
					when "date"
						self[:value] = v
					when "string"
						self[:value] = v
				end
			else
				self[:value] = v
			end
		end
	end
end