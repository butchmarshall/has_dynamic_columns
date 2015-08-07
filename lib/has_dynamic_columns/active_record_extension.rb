module HasDynamicColumns
	module ActiveRecordExtension
		def self.included(base)
			base.send :extend, ClassMethods
			base.send :extend, QueryMethods
			base.send :include, InstanceMethods
		end

		module QueryMethods

			# lifted from
			# http://erniemiller.org/2013/10/07/activerecord-where-not-sane-true/
			module WhereChainCompatibility
				include ::ActiveRecord::QueryMethods
				define_method :build_where,
					::ActiveRecord::QueryMethods.instance_method(:build_where)
			end

			def where(opts = :chain, *rest)
				puts "WE ARE MODIFYING MAHAHAHAHAH"
				if opts == :chain
					scope = spawn
					scope.extend(WhereChainCompatibility)
					::ActiveRecord::QueryMethods::WhereChain.new(scope)
				else
					super
				end
			end
		end

		module ClassMethods
			def hahahahaha
				"this is a class method"
			end
		end
		module InstanceMethods
			def haha?
				"TTHSI IS FRON THE INSTANCE"
			end
		end
	end
end