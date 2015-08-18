module HasDynamicColumns
	class DynamicColumnDatum < ::ActiveRecord::Base
		belongs_to :dynamic_column, :class_name => "HasDynamicColumns::DynamicColumn"
		belongs_to :dynamic_column_option, :class_name => "HasDynamicColumns::DynamicColumnOption"
		belongs_to :owner, :polymorphic => true

		belongs_to :datum, :polymorphic => true

		def value=v
			data_type = "string"
			data_type = self.dynamic_column.data_type if self.dynamic_column

			self.datum = "::HasDynamicColumns::DynamicColumn#{data_type.capitalize}Datum".constantize.new(value: v)
		end
		def value
			self.datum.value if self.datum
		end
	end
end