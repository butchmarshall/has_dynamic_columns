# ActiveRecord v3 specific changes

module HasDynamicColumns
	module ActiveRecord
		module QueryMethods
			module ClassMethods
				def self.included base
					base.class_eval do
						def preprocess_order_args(order_args)
							order_args.flatten!
							#validate_order_args(order_args)

							references = order_args.grep(String)
							references.map! { |arg| arg =~ /^([a-zA-Z]\w*)\.(\w+)/ && $1 }.compact!
							references!(references) if references.any?

							# if a symbol is given we prepend the quoted table name
							order_args.map! do |arg|
								case arg
								when Symbol
									#arg = klass.attribute_alias(arg) if klass.attribute_alias?(arg)
									table[arg].asc
								when Hash
									arg.map { |field, dir|
										#field = klass.attribute_alias(field) if klass.attribute_alias?(field)
										table[field].send(dir.downcase)
									}
								else
									arg
								end
							end.flatten!
						end
					end
				end
			end

			# lifted from
			# http://erniemiller.org/2013/10/07/activerecord-where-not-sane-true/
			class WhereChain
				def initialize(scope)
					@scope = scope
				end

				# Extends where to chain a has_dynamic_columns method
				# This builds all the joins needed to search the has_dynamic_columns_data tables
				def has_dynamic_columns(opts = :chain, *rest)
					# Map
					dynamic_columns_value = {
						:scope => nil,
						:where => @scope.send(:build_where, opts, rest)
					}
					@scope.where_dynamic_columns_values = dynamic_columns_value

					chain = ::ActiveRecord::QueryMethods::WhereChain.new(@scope)
					chain.instance_eval do
						# Make outer scope variable accessible
						@dynamic_columns_value = dynamic_columns_value

						# Extends where to chain with a has_scope method
						# This scopes the where from above
						def with_scope(opt)
							@dynamic_columns_value[:scope] = opt

							@scope
						end
						def without_scope
							@scope
						end
					end

					chain
				end
			end

			def where_with_dynamic_columns(opts = :chain, *rest)
				if opts == :chain
					::ActiveRecord::QueryMethods::WhereChain.new(clone)
				else
					where_without_dynamic_columns(opts, *rest)
				end
			end

			def order_with_dynamic_columns(*args)
				# Chain - by_dynamic_columns
				if args.empty?
					::ActiveRecord::QueryMethods::OrderChain.new(clone)
				else
					order_without_dynamic_columns(*args)
				end
			end
		end
	end
end
