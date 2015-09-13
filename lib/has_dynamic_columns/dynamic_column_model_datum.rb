module HasDynamicColumns
	class DynamicColumnModelDatum < ::ActiveRecord::Base
		has_one :dynamic_column_datum, :as => :datum
		belongs_to :value, :polymorphic => true
	end
end