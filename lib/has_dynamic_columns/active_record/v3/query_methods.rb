module HasDynamicColumns
	module ActiveRecord
		module QueryMethods
			def self.included(base)
				base.class_eval do
					alias_method_chain :order, :dynamic_columns
					alias_method_chain :where, :dynamic_columns
					alias_method_chain :build_arel, :dynamic_columns

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


					def dynamic_column_process_arel_nodes(rel, scope, index, joins)
						case rel
						when Arel::Nodes::Grouping
							dynamic_column_process_arel_nodes(rel.expr, scope, index+1, joins)
						when Arel::Nodes::Or
							dynamic_column_process_arel_nodes(rel.left, scope, index+1, joins)
							dynamic_column_process_arel_nodes(rel.right, scope, index+10000, joins) # Hack - queries with over 10,000 dynamic where conditions may break
						when Arel::Nodes::And
							dynamic_column_process_arel_nodes(rel.left, scope, index+1, joins)
							dynamic_column_process_arel_nodes(rel.right, scope, index+10000, joins) # Hack - queries with over 10,000 dynamic where conditions may break
						# We can work with this
						when Arel::Nodes::Descending
							col_name = rel.expr.name
							dynamic_type = rel.expr.relation.engine

							rel.expr.relation = dynamic_column_build_arel_joins(col_name, dynamic_type, scope, index+1, joins)[:table]
							rel.expr.name = :value
						# We can work with this
						when Arel::Nodes::Ascending
							col_name = rel.expr.name
							dynamic_type = rel.expr.relation.engine

							rel.expr.relation = dynamic_column_build_arel_joins(col_name, dynamic_type, scope, index+1, joins)[:table]
							rel.expr.name = :value
						# We can work with this
						else
							col_name = rel.left.name
							dynamic_type = rel.left.relation.engine.to_s

							rel.left.relation = dynamic_column_build_arel_joins(col_name, dynamic_type, scope, index+1, joins)[:table] # modify the where to use the aliased table
							rel.left.name = :value # value is the data storage column searchable on dynamic_column_data table
						end
					end

					# Builds the joins required for this dynamic column
					# Modifies the where to use the dynamic_column_data table alias
					#
					# rel - an arel node
					# scope - scope to run the conditions in
					# index - unique table identifier
					# joins - list of joins processed (to prevent duplicates)
					def dynamic_column_build_arel_joins(col_name, dynamic_type, scope, index, joins)
						field_scope = scope
						field_scope_id = (!field_scope.nil?) ? field_scope.id : nil
						field_scope_type = (!field_scope.nil?) ? field_scope.class.name.constantize.to_s : nil

						joins_scope_key = "#{field_scope_type}_#{field_scope_id}"
						joins[joins_scope_key] ||= {}

						column_datum_store_table_type = "HasDynamicColumns::DynamicColumnStringDatum"
						if !field_scope.nil? && a = field_scope.activerecord_dynamic_columns.where(key: col_name).first
							column_datum_store_table_type = "HasDynamicColumns::DynamicColumn#{a.data_type.to_s.capitalize}Datum"
						end

						column_table = HasDynamicColumns::DynamicColumn.arel_table.alias("dynamic_where_#{index}_#{col_name}")
						column_datum_table = HasDynamicColumns::DynamicColumnDatum.arel_table.alias("dynamic_where_data_#{index}_#{col_name}")
						column_datum_store_table = column_datum_store_table_type.constantize.arel_table.alias("dynamic_where_data_store_#{index}_#{col_name}")

						# Join for this scope/col already added - continue
						if !joins[joins_scope_key][col_name].nil?
							return joins[joins_scope_key][col_name]
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
														column_datum_table[:owner_type].eq(dynamic_type.to_s)
													).and(
														column_datum_table[:dynamic_column_id].eq(column_table[:id])
													)
												)

						column_table_datum_join = table.create_join(column_datum_table, column_table_datum_join_on, Arel::Nodes::OuterJoin)
						self.joins_values += [column_table_datum_join]

						# Join on the actual data
						column_table_datum_store_join_on = column_datum_store_table
												.create_on(
													column_datum_table[:datum_id].eq(column_datum_store_table[:id]).and(
														column_datum_table[:datum_type].eq(column_datum_store_table_type)
													)
												)

						column_table_datum_store_join = table.create_join(column_datum_store_table, column_table_datum_store_join_on, Arel::Nodes::OuterJoin)
						self.joins_values += [column_table_datum_store_join]

						joins[joins_scope_key][col_name] = {
							:join => column_table_datum_store_join,
							:table => column_datum_store_table
						}

						joins[joins_scope_key][col_name]
					end

					# Builds all the joins required for the dynamic columns in the where/order clauses
					def build_dynamic_column_joins
						joins = {}

						self.where_dynamic_columns_values.each_with_index { |dynamic_scope, index_outer|
							dynamic_scope[:where].each_with_index { |rel, index_inner|
								# Process each where
								dynamic_column_process_arel_nodes(rel, dynamic_scope[:scope], (index_outer*1000)+(index_inner*10000), joins)

								# Warning
								# Must cast rel to a string - I've encountered ***strange*** situations where this will change the 'col_name' to value in the where clause
								# specifically, the test 'case should restrict if scope specified' will fail
								self.where_values += [rel.to_sql]
							}
						}
						self.order_dynamic_columns_values.each_with_index { |dynamic_scope, index_outer|
							dynamic_scope[:order].each_with_index { |rel, index_inner|
								# Process each order
								dynamic_column_process_arel_nodes(rel, dynamic_scope[:scope], (index_outer*1000)+(index_inner*10000), joins)	
							}
						}

						true
					end
				end
			end

			# When arel starts building - filter
			def build_arel_with_dynamic_columns
				self.build_dynamic_column_joins

				if self.where_dynamic_columns_values.length > 0 || self.order_dynamic_columns_values.length > 0
					self.group_values += [Arel::Nodes::Group.new(table[:id])]
				end

				build_arel_without_dynamic_columns
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
					where_without_dynamic_columns(opts, rest)
				end
			end

			# OrderChain objects act as placeholder for queries in which #order does not have any parameter.
			# In this case, #order must be chained with #by_dynamic_columns to return a new relation.
			class OrderChain
				def initialize(scope)
					@scope = scope
				end

				def by_dynamic_columns(*args)
					@scope.send(:preprocess_order_args, args)

					# Add now - want to keep the order with the regular column orders
					@scope.order_values += args

					# Map
					dynamic_columns_value = {
						:scope => nil,
						:order => args,
					}
					@scope.order_dynamic_columns_values = dynamic_columns_value

					chain = ::ActiveRecord::QueryMethods::OrderChain.new(@scope)
					chain.instance_eval do
						# Make outer scope variable accessible
						@dynamic_columns_value = dynamic_columns_value

						# Extends where to chain with a has_scope method
						# This scopes the where from above
						def with_scope(opt)
							@dynamic_columns_value[:scope] = opt

							@scope
						end
					end

					chain
				end
			end

			def order_with_dynamic_columns(opts = :chain)
				# Chain - by_dynamic_columns
				if opts == :chain
					::ActiveRecord::QueryMethods::OrderChain.new(clone)
				else
					order_without_dynamic_columns(opts)
				end
			end
		end
	end
end
