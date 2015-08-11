module HasDynamicColumns
	class DynamicColumn < ::ActiveRecord::Base
		has_many :dynamic_column_options, :class_name => "HasDynamicColumns::DynamicColumnOption"
		has_many :dynamic_column_validations, :class_name => "HasDynamicColumns::DynamicColumnValidation"
	end
end