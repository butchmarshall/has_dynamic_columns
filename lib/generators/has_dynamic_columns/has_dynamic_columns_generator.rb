require 'rails/generators/base'
require 'has_dynamic_columns/compatibility'

class HasDynamicColumnsGenerator < Rails::Generators::Base
  source_paths << File.join(File.dirname(__FILE__), 'templates')
end
