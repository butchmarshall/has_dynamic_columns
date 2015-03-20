source 'https://rubygems.org'

gem 'rake'

group :test do
	if ENV['RAILS_VERSION'] == 'edge'
		gem 'activerecord', :github => 'rails/rails'
	else
		gem 'activerecord', (ENV['RAILS_VERSION'] || ['>= 3.0', '< 5.0'])
	end
	
	gem 'coveralls', :require => false
	gem 'rspec', '>= 3'
	gem 'rubocop', '>= 0.25'
end

# Specify your gem's dependencies in has_dynamic_columns.gemspec
gemspec

