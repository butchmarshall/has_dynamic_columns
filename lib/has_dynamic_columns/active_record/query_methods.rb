module HasDynamicColumns
	module ActiveRecord
		module QueryMethods
			def self.included(base)
				base.class_eval do
					alias_method_chain :where, :dynamic_columns
					alias_method_chain :build_arel, :dynamic_columns

					# Recurses through arel nodes until it finds one it can work with
					def dynamic_column_process_nodes(rel, scope, index)
						case rel
						when Arel::Nodes::Grouping
							dynamic_column_process_nodes(rel.expr, scope, index+1)
						when Arel::Nodes::Or
							dynamic_column_process_nodes(rel.left, scope, index+1)
							dynamic_column_process_nodes(rel.right, scope, index+10000) # Hack - queries with over 10,000 dynamic where conditions may break
						when Arel::Nodes::And
							dynamic_column_process_nodes(rel.left, scope, index+1)
							dynamic_column_process_nodes(rel.right, scope, index+10000) # Hack - queries with over 10,000 dynamic where conditions may break
						# We can work with this
						else	
							dynamic_column_build_arel_joins_and_modify_wheres(rel, scope, index+1)
						end
					end

					# Builds the joins required for this dynamic column
					# Modifies the where to use the dynamic_column_data table alias
					#
					# rel - an arel node
					# scope - scope to run the conditions in
					# index - unique table identifier
					def dynamic_column_build_arel_joins_and_modify_wheres(rel, scope, index)
						col_name = rel.left.name
						value = rel.right

						field_scope = scope
						field_scope_id = (!field_scope.nil?) ? field_scope.id : nil
						field_scope_type = (!field_scope.nil?) ? field_scope.class.name.constantize.to_s : nil

						column_table = HasDynamicColumns::DynamicColumn.arel_table.alias("dynamic_where_#{index}_#{col_name}")
						column_datum_table = HasDynamicColumns::DynamicColumnDatum.arel_table.alias("dynamic_where_data_#{index}_#{col_name}")

						dynamic_type = rel.left.relation.engine.to_s
						rel.left.relation = column_datum_table # modify the where to use the aliased table
						rel.left.name = :value # value is the data storage column searchable on dynamic_column_data table

						rel.right = case rel.right
						# Map true -> 1
						when ::TrueClass
							1
						# Map false -> 0
						when ::FalseClass
							0
						else
							rel.right
						end

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

						# Join on all the data with the provided key
						column_table_datum_join_on = column_datum_table
												.create_on(
													column_datum_table[:owner_id].eq(table[:id]).and(
														column_datum_table[:owner_type].eq(dynamic_type)
													).and(
														column_datum_table[:dynamic_column_id].eq(column_table[:id])
													)
												)

						column_table_datum_join = table.create_join(column_datum_table, column_table_datum_join_on, Arel::Nodes::OuterJoin)
						self.joins_values += [column_table_datum_join]

					end
				end
			end

			# When arel starts building - filter
			def build_arel_with_dynamic_columns
				# Calculate any dynamic scope that was passed
				self.has_dynamic_columns_values.each_with_index { |dynamic_scope, index_outer|
					dynamic_scope[:where].each_with_index { |rel, index_inner|
						# Process each where
						dynamic_column_process_nodes(rel, dynamic_scope[:scope], (index_outer*1000)+(index_inner*10000))

						# It's now safe to use the original where query
						# All the conditions in rel have been modified to be a where of the aliases dynamic_where_data table
						
						# Warning
						# Must cast rel to a string - I've encountered ***strange*** situations where this will change the 'col_name' to value in the where clause
						# specifically, the test 'case should restrict if scope specified' will fail
						self.where_values += [rel.to_sql]
					}
				}
				# At least one dynamic where run - we need to group or we're going to get duplicates
				if self.has_dynamic_columns_values.length > 0
					self.group_values += [Arel::Nodes::Group.new(table[:id])]
				end

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
		end
	end
end
