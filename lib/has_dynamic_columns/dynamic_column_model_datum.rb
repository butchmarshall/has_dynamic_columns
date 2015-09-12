module HasDynamicColumns
	class DynamicColumnModelDatum < ::ActiveRecord::Base
		belongs_to :dynamic_column_datum, :class_name => "HasDynamicColumns::DynamicColumnDatum"
		belongs_to :value, :polymorphic => true
	end
end