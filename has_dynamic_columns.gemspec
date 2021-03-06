# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_dynamic_columns/version'

Gem::Specification.new do |spec|
	spec.name          = "has_dynamic_columns"
	spec.version       = HasDynamicColumns::VERSION
	spec.authors       = ["Butch Marshall"]
	spec.email         = ["butch.a.marshall@gmail.com"]
	spec.summary       = "Dynamic fields for activerecord models"
	spec.description   = "Adds ability to put dynamic fields into active record models"
	spec.homepage      = "https://github.com/butchmarshall/has_dynamic_columns"
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_dependency "activerecord", [">= 3.0", "< 5.0"]
	if RUBY_PLATFORM == 'java'
		spec.add_development_dependency "jdbc-sqlite3", "> 0"
		spec.add_development_dependency "activerecord-jdbcsqlite3-adapter", "> 0"
	else
		spec.add_development_dependency "sqlite3", "> 0"
	end
	spec.add_development_dependency "factory_girl", "> 4.0"
	spec.add_development_dependency "bundler", "~> 1.7"
	spec.add_development_dependency "rake", "~> 10.0"
end
