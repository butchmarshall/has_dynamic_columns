module HasDynamicColumns
	class DynamicColumnBooleanDatum < ::ActiveRecord::Base
		has_one :dynamic_column_datum, :as => :datum
	end
end