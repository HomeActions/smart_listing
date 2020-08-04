# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'smart_listing/version'

Gem::Specification.new do |s|
  s.name        = 'smart_listing'
  s.version     = SmartListing::VERSION
  s.authors     = %w[HomeActions]
  s.email       = ['webmaster@homeactions.net']
  s.homepage    = 'https://github.com/HomeActions/smart_listing'
  s.description = 'Rails data listing gem with built-in sorting, filtering and in-place editing.'
  s.summary     = 'SmartListing helps creating sortable lists of ActiveRecord collections with pagination, filtering and inline editing.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  # s.add_dependency 'pagy', '>=3.8.3'
  s.add_dependency 'kaminari', '>= 0.17'
  s.add_dependency 'rails', '>=5.2'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'

  s.add_development_dependency 'capybara', '< 2.14'
  s.add_development_dependency 'database_cleaner'
end
