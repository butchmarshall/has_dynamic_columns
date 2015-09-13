module HasDynamicColumns
	class DynamicColumnDatetimeDatum < ::ActiveRecord::Base
		has_one :dynamic_column_datum, :as => :datum
	end
end