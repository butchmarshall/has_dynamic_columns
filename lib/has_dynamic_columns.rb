require "active_support"
require 'active_support/dependencies'
require "active_record"

require "has_dynamic_columns/active_record/query_methods"
require "has_dynamic_columns/active_record/relation"

require "has_dynamic_columns/model"
require "has_dynamic_columns/version"
require "has_dynamic_columns/dynamic_column"
require "has_dynamic_columns/dynamic_column_option"
require "has_dynamic_columns/dynamic_column_validation"
require "has_dynamic_columns/dynamic_column_datum"

require "has_dynamic_columns/dynamic_column_boolean_datum"
require "has_dynamic_columns/dynamic_column_date_datum"
require "has_dynamic_columns/dynamic_column_datetime_datum"
require "has_dynamic_columns/dynamic_column_enum_datum"
require "has_dynamic_columns/dynamic_column_float_datum"
require "has_dynamic_columns/dynamic_column_integer_datum"
require "has_dynamic_columns/dynamic_column_string_datum"
require "has_dynamic_columns/dynamic_column_text_datum"
require "has_dynamic_columns/dynamic_column_time_datum"
require "has_dynamic_columns/dynamic_column_timestamp_datum"
require "has_dynamic_columns/dynamic_column_model_datum"

module HasDynamicColumns
end

if defined?(Rails::Railtie)
	class Railtie < Rails::Railtie
		initializer 'has_dynamic_columns.insert_into_active_record' do
			ActiveSupport.on_load :active_record do
				ActiveRecord::Base.send(:include, HasDynamicColumns::Model)
				ActiveRecord::Relation.send(:include, HasDynamicColumns::ActiveRecord::Relation)
				ActiveRecord::QueryMethods.send(:include, HasDynamicColumns::ActiveRecord::QueryMethods)
			end
		end
	end
elsif defined?(ActiveRecord)
	ActiveRecord::Base.send(:include, HasDynamicColumns::Model)
	ActiveRecord::Relation.send(:include, HasDynamicColumns::ActiveRecord::Relation)
	ActiveRecord::QueryMethods.send(:include, HasDynamicColumns::ActiveRecord::QueryMethods)
end