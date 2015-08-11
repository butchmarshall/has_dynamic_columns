module HasDynamicColumns
	module ActiveRecordRelation
		def self.included(base)
			base.class_eval do
			end

			base.instance_eval do
			end
		end

		# lifted from
		# http://erniemiller.org/2013/10/07/activerecord-where-not-sane-true/
		module WhereChainCompatibility
			module_function
			include ::ActiveRecord::QueryMethods
			define_method :build_where,
				::ActiveRecord::QueryMethods.instance_method(:build_where)
		end

		def where(opts = :chain, *rest)
			if opts == :chain
				scope = spawn
				scope.extend(WhereChainCompatibility)
				chain = ::ActiveRecord::QueryMethods::WhereChain.new(scope)
				chain.instance_eval do
					# Provide search on dynamic columns
					def dynamic(opts, *rest)				
						options = rest.extract_options!
						field_scope = opts.respond_to?(:class) && opts.class.respond_to?(:ancestors) && (opts.class.ancestors.include?(::ActiveRecord::Base)) ? opts : nil

						# Field scope passed to the where clause
						if !field_scope.nil?
							opts = options
							rest = []
						end

						field_scope_id = (!field_scope.nil?) ? field_scope.id : nil
						field_scope_type = (!field_scope.nil?) ? field_scope.class.name.constantize.to_s : nil

						# Join dynamic_column table
						# This filter by scope if field_scope is passed
						@scope.joins_values += @scope.send(:build_where, opts, rest).map do |rel|
							dynamic_type = rel.left.relation.engine.to_s

							col_name = rel.left.name
							value = rel.right

							table = dynamic_type.constantize.arel_table
							column_table = ::HasDynamicColumns::DynamicColumn.arel_table.alias("dynamic_where_#{col_name}")

							on_query = column_table[:key].eq(col_name)
							if !field_scope_type.nil?
								on_query = on_query.and(
									column_table[:field_scope_type].eq(field_scope_type)
								)
							end
							if !field_scope_id.nil?
								on_query = on_query.and(
									column_table[:field_scope_id].eq(field_scope_id)
								)
							end

							column_table_join_on = column_table.create_on(on_query)
							table.create_join(column_table, column_table_join_on)
						end unless field_scope.nil?

						# Join dynamic_column_data table
						# This filters on data irrigardless of scope
						join_value = @scope.send(:build_where, opts, rest).map do |rel|
							dynamic_type = rel.left.relation.engine.to_s

							col_name = rel.left.name
							value = rel.right

							table = dynamic_type.constantize.arel_table
							column_table = ::HasDynamicColumns::DynamicColumn.arel_table.alias("dynamic_where_#{col_name}")
							column_datum_table = ::HasDynamicColumns::DynamicColumnDatum.arel_table.alias("dynamic_where_data_#{col_name}")

							# Join on all the data with the provided key
							column_table_datum_join_on = column_datum_table
													.create_on(
														column_datum_table[:owner_id].eq(table[:id]).and(
															column_datum_table[:owner_type].eq(dynamic_type)
														).and(
															column_datum_table[:dynamic_column_id].eq(column_table[:id])
														).and(
															column_datum_table[:value].matches("%"+value+"%")
														)
													)

							table.create_join(column_datum_table, column_table_datum_join_on)
						end
						@scope.joins_values += join_value

						@scope
					end
				end
				
				chain
			else
				super
			end
		end
	end
end