module HasDynamicColumns
	class DynamicColumnDateDatum < ::ActiveRecord::Base
		belongs_to :dynamic_column_datum, :class_name => "HasDynamicColumns::DynamicColumnDatum"
	end
end