module HasDynamicColumns
	module ActiveRecord
		def self.included(base)
			base.extend ClassMethods
			
		end

		module ClassMethods
			include HasDynamicColumns::ActiveRecordRelation
		end
	end
end