require "active_support"

require "has_dynamic_columns/version"
require "has_dynamic_columns/dynamic_column"
require "has_dynamic_columns/dynamic_column_option"
require "has_dynamic_columns/dynamic_column_validation"
require "has_dynamic_columns/dynamic_column_datum"

module HasDynamicColumns
	module Model
		def self.included(base)
			base.send :extend, ClassMethods
		end

		module ClassMethods
			def has_dynamic_columns(*args)
				options = args.extract_options!
				configuration = {
					:as => "dynamic_columns",
					:field_scope => nil,
				}
		        configuration.update(options) if options.is_a?(Hash)

				class_eval <<-EOV
					include ::HasDynamicColumns::Model::InstanceMethods

					has_many :activerecord_#{configuration[:as]},
								class_name: "HasDynamicColumns::DynamicColumn",
								as: :field_scope
					has_many :activerecord_#{configuration[:as]}_data,
								class_name: "HasDynamicColumns::DynamicColumnDatum",
								as: :owner

					# only add to attr_accessible
					# if the class has some mass_assignment_protection
					if defined?(accessible_attributes) and !accessible_attributes.blank?
						#attr_accessible :#{configuration[:column]}
					end

					validate :validate_dynamic_column_data

					public
						def as_json(*args)
							json = super(*args)
							json[json.keys.first][self.dynamic_columns_as] = self.send(self.dynamic_columns_as)
							json
						end

						# Setter for dynamic field data
						def #{configuration[:as]}=data
							data.each_pair { |key, value|
								# We dont play well with this key
								if !self.storable_#{configuration[:as].to_s.singularize}_key?(key)
									raise NoMethodError
								end
								dynamic_column = self.#{configuration[:as].to_s.singularize}_key_to_dynamic_column(key)

								# We already have this key in database
								if existing = self.activerecord_#{configuration[:as]}_data.select { |i| i.dynamic_column == dynamic_column }.first
									existing.value = value
								else
									self.activerecord_#{configuration[:as]}_data.build(:dynamic_column => dynamic_column, :value => value)
								end
							}
						end

						def #{configuration[:as]}
							h = {}
							self.field_scope_#{configuration[:as]}.each { |i|
								h[i.key] = nil
							}
							self.activerecord_#{configuration[:as]}_data.each { |i|
								h[i.dynamic_column.key] = i.value unless !i.dynamic_column
							}
							h
						end

						def #{configuration[:as].to_s.singularize}_keys
							self.field_scope_#{configuration[:as]}.collect { |i| i.key }
						end

						def field_scope_#{configuration[:as]}
							self.field_scope.send("activerecord_"+self.field_scope.dynamic_columns_as).select { |i|
								# Only get things with no dynamic type defined or dynamic types defined as this class
								i.dynamic_type.to_s.empty? || i.dynamic_type.to_s == self.class.to_s
							}
						end

						def dynamic_columns_as
							"#{configuration[:as].to_s}"
						end

					protected
						# Whether this is storable
						def storable_#{configuration[:as].to_s.singularize}_key?(key)
							self.#{configuration[:as].to_s.singularize}_keys.include?(key.to_s)
						end

						# Figures out which dynamic_column has which key
						def #{configuration[:as].to_s.singularize}_key_to_dynamic_column(key)
							found = nil
							if record = self.send("field_scope_"+self.dynamic_columns_as).select { |i| i.key == key.to_s }.first
								found = record
							end
							found
						end

						def field_scope
							#{configuration[:field_scope]}
						end
				EOV
			end
		end

		module InstanceMethods
			# Validate all the dynamic_column_data at once
			def validate_dynamic_column_data
				field_scope = self.field_scope

				if field_scope
					# All the fields defined on the parent model
					dynamic_columns = field_scope.send("activerecord_#{field_scope.dynamic_columns_as}")

					self.send("activerecord_#{self.dynamic_columns_as}_data").each { |dynamic_column_datum|
						# Collect all validation errors
						validation_errors = []

						if dynamic_column_datum.dynamic_column_option_id == -1
							validation_errors << "invalid_option"
						end

						# Find the dynamic_column defined for this datum
						dynamic_column = nil
						dynamic_columns.each { |i|
							if i == dynamic_column_datum.dynamic_column
								dynamic_column = i
								break
							end
						}
						# We have a dynamic_column - validate
						if dynamic_column
							dynamic_column.dynamic_column_validations.each { |validation|
								if !validation.is_valid?(dynamic_column_datum.value.to_s)
									validation_errors << validation.error
								end
							}
						else
							# No field found - this is probably bad - should we throw an error?
							validation_errors << "not_found"
						end

						# If any errors exist - add them
						if validation_errors.length > 0
							errors.add(:dynamic_columns, { "#{dynamic_column.key}" => validation_errors })
						end
					}
				end
			end
		end
	end
end

if defined?(Rails::Railtie)
	class Railtie < Rails::Railtie
		initializer 'has_dynamic_columns.insert_into_active_record' do
			ActiveSupport.on_load :active_record do
				ActiveRecord::Base.send(:include, HasDynamicColumns::Model)
			end
		end
	end
else
	ActiveRecord::Base.send(:include, HasDynamicColumns::Model) if defined?(ActiveRecord)
end