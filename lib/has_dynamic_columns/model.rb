require "has_dynamic_columns/model/class_methods"
require "has_dynamic_columns/model/instance_methods"

module HasDynamicColumns
	module Model
		def self.included(base)
			base.send :extend, ClassMethods
		end
	end
end