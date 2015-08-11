module HasDynamicColumns
	class DynamicColumnOption < ::ActiveRecord::Base
		belongs_to :dynamic_column, :class_name => "HasDynamicColumns::DynamicColumn"
	end
end