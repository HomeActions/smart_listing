require_relative "lib/smart_listing/version"

Gem::Specification.new do |spec|
  spec.name        = "smart_listing"
  spec.version     = SmartListing::VERSION
  spec.authors     = ["Sology"]
  spec.email       = ["contact@sology.eu"]
  spec.homepage    = "https://github.com/Sology/smart_listing"
  spec.summary     = "SmartListing helps creating sortable lists of ActiveRecord collections with pagination, filtering and inline editing."
  spec.description = "Ruby on Rails data listing gem with built-in sorting, filtering and in-place editing."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Sology/smart_listing"
  spec.metadata["changelog_uri"] = "https://github.com/Sology/smart_listing/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "kaminari", ">= 1.2"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "webdrivers"
  spec.add_development_dependency "database_cleaner"
end
