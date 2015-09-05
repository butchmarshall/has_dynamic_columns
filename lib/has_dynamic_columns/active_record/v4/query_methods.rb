# ActiveRecord v4 specific changes

module HasDynamicColumns
	module ActiveRecord
		module QueryMethods
			module ClassMethods
			end

			# lifted from
			# http://erniemiller.org/2013/10/07/activerecord-where-not-sane-true/
			module WhereChainCompatibility
				#include ::ActiveRecord::QueryMethods
				#define_method :build_where,
				#	::ActiveRecord::QueryMethods.instance_method(:build_where)

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
					scope = spawn
					chain = ::ActiveRecord::QueryMethods::WhereChain.new(scope)
					chain.send(:extend, WhereChainCompatibility)
				else
					where_without_dynamic_columns(opts, *rest)
				end
			end

			def order_with_dynamic_columns(opts = :chain)
				# Chain - by_dynamic_columns
				if opts == :chain
					::ActiveRecord::QueryMethods::OrderChain.new(spawn)
				else
					order_without_dynamic_columns(opts)
				end
			end
		end
	end
end
