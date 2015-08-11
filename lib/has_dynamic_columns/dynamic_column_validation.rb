module HasDynamicColumns
	class DynamicColumnValidation < ::ActiveRecord::Base
		belongs_to :dynamic_column, :class_name => "HasDynamicColumns::DynamicColumn"

		def is_valid?(str)
			matches = Regexp.new(self["regexp"]).match(str.to_s)

			return !matches.nil?
		end
	end
end