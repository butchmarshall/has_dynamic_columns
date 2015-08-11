module HasDynamicColumns
	module ActiveRecord
		module QueryMethods
			def self.included(base)

				base.class_eval do
					alias_method_chain :where, :dynamic_columns
					alias_method_chain :build_arel, :dynamic_columns
				end

				base.instance_eval do
				end
			end

			# When arel starts building - filter
			def build_arel_with_dynamic_columns
				#arel = Arel::SelectManager.new(table.engine, table)

				# Calculate any dynamic scope that was passed
				self.has_dynamic_columns_values.each { |dynamic_scope|
					field_scope = dynamic_scope[:scope]	
					field_scope_id = (!field_scope.nil?) ? field_scope.id : nil
					field_scope_type = (!field_scope.nil?) ? field_scope.class.name.constantize.to_s : nil

					# TODO - make this work on compound arel queries like: table[:last_name].eq("Paterson").or(table[:first_name].eq("John"))
					#collapsed = collapse_wheres(arel, dynamic_scope[:where])

					dynamic_scope[:where].each_with_index { |rel, index|
						case rel
						when String
							next
						else
							dynamic_type = rel.left.relation.engine.to_s
							col_name = rel.left.name
							value = rel.right
						end

						column_table = HasDynamicColumns::DynamicColumn.arel_table.alias("dynamic_where_#{index}_#{col_name}")
						column_datum_table = HasDynamicColumns::DynamicColumnDatum.arel_table.alias("dynamic_where_data_#{index}_#{col_name}")

						# Join on the column with the key
						on_query = column_table[:key].eq(col_name)
						on_query = on_query.and(
							column_table[:field_scope_type].eq(field_scope_type)
						) unless field_scope_type.nil?

						on_query = on_query.and(
							column_table[:field_scope_id].eq(field_scope_id)
						) unless field_scope_id.nil?

						column_table_join_on = column_table
												.create_on(
													on_query
												)

						column_table_join = table.create_join(column_table, column_table_join_on)
						self.joins_values += [column_table_join]

						arel_node = case rel
							when Arel::Nodes::Equality
								column_datum_table[:value].eq(value)
							else
								column_datum_table[:value].matches(value)
						end

						# Join on all the data with the provided key
						column_table_datum_join_on = column_datum_table
												.create_on(
													column_datum_table[:owner_id].eq(table[:id]).and(
														column_datum_table[:owner_type].eq(dynamic_type)
													).and(
														column_datum_table[:dynamic_column_id].eq(column_table[:id])
													).and(
														arel_node
													)
												)

						column_table_datum_join = table.create_join(column_datum_table, column_table_datum_join_on)
						self.joins_values += [column_table_datum_join]
					}
				}

				build_arel_without_dynamic_columns
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
					@scope.has_dynamic_columns_values = dynamic_columns_value

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
					where_without_dynamic_columns(opts, rest)
				end
			end
=begin
			def where_with_dynamic_columns(opts = :chain, *rest)
				puts "--------------------------------------"
				puts "Calling where_with_dynamic_columns"
				puts opts.inspect
				puts rest.inspect
				
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
					# Default where
					where_without_dynamic_columns(opts, rest)
				end
			end
=end
		end
	end
end
