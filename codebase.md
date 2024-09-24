# smart_listing.gemspec

```gemspec
$:.push File.expand_path("../lib", __FILE__)

require "smart_listing/version"

Gem::Specification.new do |s|
  s.name        = "smart_listing"
  s.version     = SmartListing::VERSION
  s.authors     = ["Sology"]
  s.email       = ["contact@sology.eu"]
  s.homepage    = "https://github.com/Sology/smart_listing"
  s.description = "Ruby on Rails data listing gem with built-in sorting, filtering and in-place editing."
  s.summary     = "SmartListing helps creating sortable lists of ActiveRecord collections with pagination, filtering and inline editing."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">=3.2"
  s.add_dependency "coffee-rails"
  s.add_dependency "kaminari", ">= 0.17"
  s.add_dependency "jquery-rails"

  s.add_development_dependency "bootstrap-sass"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "byebug"

  s.add_development_dependency "capybara", "< 2.14"
  s.add_development_dependency "capybara-webkit", "~> 1.14"
  s.add_development_dependency "database_cleaner"
end

```

# Rakefile

```
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SmartListing'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'



Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end


task default: :test

```

# README.md

```md
# SmartListing

SmartListing helps creating AJAX-enabled lists of ActiveRecord collections or arrays with pagination, filtering, sorting and in-place editing.

[See it in action](http://showcase.sology.eu/smart_listing)

## Installation

Add to your Gemfile:

\`\`\`ruby
gem "smart_listing"
\`\`\`

Then run:

\`\`\`sh
$ bundle install
\`\`\`

Also, you need to add SmartListing to your asset pipeline:

\`\`\`
//= require smart_listing
\`\`\`

__Rails >= 5.1 users__: Rails 5.1 has dropped jQuery dependency from the default stack in favour of `rails-ujs`. SmartListing still requires jQuery so make sure that you use `jquery_ujs` from `jquery-rails` gem and have following requires in your asset pipeline before `smart_listing`:
\`\`\`
//= require jquery
//= require jquery_ujs
\`\`\`

### Initializer

Optionally you can also install some configuration initializer:

\`\`\`sh
$ rails generate smart_listing:install
\`\`\`

It will be placed in `config/initializers/smart_listing.rb` and will allow you to tweak some configuration settings like HTML classes and data attributes names.

### Custom views

SmartListing comes with some built-in views which are by default compatible with Bootstrap 3. You can easily change them after installing:

\`\`\`sh
$ rails generate smart_listing:views
\`\`\`

Files will be placed in `app/views/smart_listing`.

## Usage

Let's start with a controller. In order to use SmartListing, in most cases you need to include controller extensions and SmartListing helper methods:

\`\`\`ruby
include SmartListing::Helper::ControllerExtensions
helper  SmartListing::Helper
\`\`\`

Next, put following code in controller action you desire:

\`\`\`ruby
@users = smart_listing_create(:users, User.active, partial: "users/listing")
\`\`\`

This will create SmartListing named `:users` consisting of ActiveRecord scope `User.active` elements and rendered by partial `users/listing`. You can also use arrays instead of ActiveRecord collections. Just put `array: true` option just like for Kaminari.

In the main view (typically something like `index.html.erb` or `index.html.haml`), use this method to render listing:

\`\`\`ruby
smart_listing_render(:users)
\`\`\`

`smart_listing_render` does some magic and renders `users/listing` partial which may look like this (in HAML):

\`\`\`haml
- unless smart_listing.empty?
  %table
    %thead
      %tr
        %th User name
        %th Email
    %tbody
      - smart_listing.collection.each do |user|
        %tr
          %td= user.name
          %td= user.email

  = smart_listing.paginate
- else
  %p.warning No records!
\`\`\`

You can see that listing template has access to special `smart_listing` local variable which is basically an instance of `SmartListing::Helper::Builder`. It provides you with some helper methods that ease rendering of SmartListing:

* `Builder#paginate` - renders Kaminari pagination,
* `Builder#pagination_per_page_links` - display some link that allow you to customize Kaminari's `per_page`,
* `Builder#collection` - accesses underlying list of items,
* `Builder#empty?` - checks if collection is empty,
* `Builder#count` - returns collection count,
* `Builder#render` - basic template's `render` wrapper that automatically adds `smart_listing` local variable,

There are also other methods that will be described in detail below.

If you are using SmartListing with AJAX on (by default), one last thing required to make pagination (and other features) work is to create JS template for main view (typically something like `index.js.erb`):

\`\`\`erb
<%= smart_listing_update(:users) %>
\`\`\`

### Sorting

SmartListing supports two modes of sorting: implicit and explicit. Implicit mode is enabled by default. In this mode, you define sort columns directly in the view:

\`\`\`haml
- unless smart_listing.empty?
  %table
    %thead
      %tr
        %th= smart_listing.sortable "User name", :name
        %th= smart_listing.sortable "Email", :email
    %tbody
      - smart_listing.collection.each do |user|
        %tr
          %td= user.name
          %td= user.email

  = smart_listing.paginate
- else
  %p.warning No records!
\`\`\`

In this case `:name` and `:email` are sorting column names. `Builder#sortable` renders special link containing column name and sort order (either `asc`, `desc`, or empty value).

You can also specify default sort order in the controller:

\`\`\`ruby
@users = smart_listing_create(:users, User.active, partial: "users/listing", default_sort: {name: "asc"})
\`\`\`

Implicit mode is convenient with simple data sets. In case you want to sort by joined column names, we advise you to use explicit sorting:
\`\`\`ruby
@users = smart_listing_create :users, User.active.joins(:stats), partial: "users/listing",
                              sort_attributes: [[:last_signin, "stats.last_signin_at"]],
                              default_sort: {last_signin: "desc"}
\`\`\`

Note that `:sort_attributes` are array which of course means, that order of attributes matters.

There's also a possibility to specify available sort directions using `:sort_dirs` option which is by default `[nil, "asc", "desc"]`.

### List item management and in-place editing

In order to allow managing and editing list items, we need to reorganize our views a bit. Basically, each item needs to have its own partial:

\`\`\`haml
- unless smart_listing.empty?
  %table
    %thead
      %tr
        %th= smart_listing.sortable "User name", "name"
        %th= smart_listing.sortable "Email", "email"
        %th
    %tbody
      - smart_listing.collection.each do |user|
        %tr.editable{data: {id: user.id}}
          = smart_listing.render partial: 'users/user', locals: {user: user}
      = smart_listing.item_new colspan: 3, link: new_user_path

  = smart_listing.paginate
- else
  %p.warning No records!
\`\`\`

`<tr>` has now `editable` class and `data-id` attribute. These are essential to make it work. We've used also a new helper: `Builder#new_item`. It renders new row which is used for adding new items. `:link` needs to be valid url to new resource action which renders JS:

\`\`\`ruby
<%= smart_listing_item :users, :new, @new_user, "users/form" %>
\`\`\`

Note that `new` action does not need to create SmartListing (via `smart_listing_create`). It just initializes `@new_user` and renders JS view.

New partial for user (`users/user`) may look like this:
\`\`\`haml
%td= user.name
%td= user.email
%td.actions= smart_listing_item_actions [{name: :show, url: user_path(user)}, {name: :edit, url: edit_user_path(user)}, {name: :destroy, url: user_path(user)}]
\`\`\`

`smart_listing_item_actions` renders here links that allow to edit and destroy user item. `:show`, `:edit` and `:destroy` are built-in actions, you can also define your `:custom` actions. Again. `<td>`'s class `actions` is important.

Controller actions referenced by above urls are again plain Ruby on Rails actions that render JS like:

\`\`\`erb
<%= smart_listing_item :users, :new, @user, "users/form" %>
<%= smart_listing_item :users, :edit, @user, "users/form" %>
<%= smart_listing_item :users, :destroy, @user %>
\`\`\`

Partial name supplied to `smart_listing_item` (`users/form`) references `@user` as `object` and may look like this:

\`\`\`haml
%td{colspan: 3}
  - if object.persisted?
    %p Edit user
  - else
    %p Add user

  = form_for object, url: object.new_record? ? users_path : user_path(object), remote: true do |f|
    %p
      Name:
      = f.text_field :name
    %p
      Email:
      = f.text_field :email
    %p= f.submit "Save"
\`\`\`

And one last thing are `create` and `update` controller actions JS view:

\`\`\`ruby
<%= smart_listing_item :users, :create, @user, @user.persisted? ? "users/user" : "users/form" %>
<%= smart_listing_item :users, :update, @user, @user.valid? ? "users/user" : "users/form" %>
\`\`\`

### Controls (filtering)

SmartListing controls allow you to change somehow presented data. This is typically used for filtering records. Let's see how view with controls may look like:

\`\`\`haml
= smart_listing_controls_for(:users) do
  .filter.input-append
    = text_field_tag :filter, '', class: "search", placeholder: "Type name here", autocomplete: "off"
    %button.btn.disabled{type: "submit"}
      %span.glyphicon.glyphicon-search
\`\`\`

This gives you nice Bootstrap-enabled filter field with keychange handler. Of course you can use any other form fields in controls too.

When form field changes its value, form is submitted and request is made. This needs to be handled in controller:

\`\`\`ruby
users_scope = User.active.joins(:stats)
users_scope = users_scope.like(params[:filter]) if params[:filter]
@users = smart_listing_create :users, users_scope, partial: "users/listing"
\`\`\`

Then, JS view is rendered and your SmartListing updated. That's it!

### Simplified views

You don't need to create all the JS views in case you want to simply use one SmartListing per controller. Just use helper methods without their first attribute (name) ie. `smart_listing_create(User.active, partial: "users/listing")`. Then define two helper methods:

 * `smart_listing_resource` returning single object,
 * `smart_listing_collection` returning collection of objects.

SmartListing default views will user these methods to render your list properly.

### More customization

Apart from standard SmartListing initializer, you can also define custom config profiles. In order to do this, use following syntax:

\`\`\`ruby
SmartListing.configure(:awesome_profile) do |config|
  # put your definitions here
end
\`\`\`

In order to use this profile, create helper method named `smart_listing_config_profile` returning profile name and put into your JS `SmartListing.config.merge()` function call. `merge()` function expects parameter with config attributes hash or reads body data-attribute named `smart-listing-config`. Hash of config attributes can be obtained by using helper method `SmartListing.config(:awesome_profile).to_json`.

## Not enough?

For more information and some use cases, see the [Showcase](http://showcase.sology.eu/smart_listing)

## Credits

SmartListing uses great pagination gem Kaminari https://github.com/amatsuda/kaminari

Created by Sology http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited http://smartlanguageapps.com/

```

# LICENSE

```
The MIT License (MIT)

Copyright (c) 2013 Sology (www.sology.eu)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```

# Guardfile

```
# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features) \
#  .select{|d| Dir.exists?(d) ? d : UI.warning("Directory #{d} does not exist")}

## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"

# Note: The cmd option is now required due to the increasing number of ways
#       rspec may be run, below are examples of the most common uses.
#  * bundler: 'bundle exec rspec'
#  * bundler binstubs: 'bin/rspec'
#  * spring: 'bin/rspec' (This will use spring if running and you have
#                          installed the spring binstubs per the docs)
#  * zeus: 'zeus rspec' (requires the server to be started separately)
#  * 'just' rspec: 'rspec'

guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # Feel free to open issues for suggestions and improvements

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Rails files
  rails = dsl.rails(view_extensions: %w(erb haml slim))
  dsl.watch_spec_files_for(rails.app_files)
  dsl.watch_spec_files_for(rails.views)

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("routing/#{m[1]}_routing"),
      rspec.spec.call("controllers/#{m[1]}_controller"),
      rspec.spec.call("acceptance/#{m[1]}")
    ]
  end

  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.routes)          { "#{rspec.spec_dir}/routing" }
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }

  # Capybara features specs
  watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{m[1]}") }
  watch(rails.layouts)       { |m| rspec.spec.call("features/#{m[1]}") }

  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) do |m|
    Dir[File.join("**/#{m[1]}.feature")][0] || "spec/acceptance"
  end
end

```

# Gemfile

```
source "https://rubygems.org"

gemspec

```

# Changes.md

```md
1.2.3
-----------

- Fix sorting to mitigate possible SQL-injection and improve tests [Ivan Korunkov]

1.2.2
-----------

- Remove duplicated href key from config template #146 [nfilzi]
- Replace deprecated .any? with .present? #143 [AakLak]
- Development environment update #140 [mizinsky]
- Fix sanitize_params method #137 [mizinsky]
- Enable to configure global remote option and it to affects sortable helper #131 [kitabatake]
- Kaminari update [mizinsky]
- Update Readme for Rails >= 5.1 Users [mizinsky]

1.2.1
-----------

- Allow to render outside of controllers [bval]
- Documentation fixes [blackcofla]
- Use id.to_json so integers and uuids will both work [sevgibson]
- Fix popover in bootstrap 4 [sevgibson]
- Fix Kaminari #num_pages deprecation warning [tylerhunt]
- Add support for Turbolinks 5 [wynksaiddestroy]
- Use #empty? for AC::Params [phoffer]
- Fix indentation in some files [boy-papan]

1.2.0
-----------

- Rails 5 support and Kaminari update [akostadinov]
- Better handling of nested controls params
- Fix controls not fading out list. Related to #51
- Config now includes element templates
- Add ability to pass locals to list view [GeorgeDewar]

1.1.2
-----------

- Some bugfixing: #20, #46, #58

1.1.0
-----------

- Config profiles
- Remove duplicate href key [wynksaiddestroy]
- API refactoring [GCorbel]
- Feature Specs [GCorbel]
- Avoid smart listing controls double initialization [lacco]
- Turbolinks support [wynksaiddestroy]
- Better form controls handling
- Possibility to specify sort directions

1.0.0
-----------

- JS Events triggered on item actions
- Fix filter resetting
- Fix new item autoshow
- Possibility to pass custom title to default actions
- Confirmation tweaks
- Multiple smart listings isolation
- New sorting architecture (and implicit sorting attributes)
- Controls helper
- Slightly changed item action templates

0.9.8
-----------

- Custom popovers support

0.9.7
-----------

- Some bugfixing
- Fix listing sorting XSS bug
- Add possibility to display new item form by default
- "Save & continue" support

0.9.6
-----------

- Some bugfixing
- Initial setup generator

0.9.5
-----------

- Fix collection counting bug
- Add builtin show action
- Make CSS class and data attribute names generic and customizable (SmartListing.configure)
- Make JavaScript more customizable

0.9.4
-----------

- Possibility to callback action
- Changes in templates

0.9.3
-----------

- Possibility to specify kaminari options
- Possibility to generate views and customize them in the app
- Better custom action handling

0.9.2
-----------

- Add possibility to specify available page sizes in options hash

0.9.0
-----------

- Initial release

```

# .gitignore

```
*.rbc
*.sassc
.sass-cache
capybara-*.html
.rspec
.rvmrc
/.bundle
/vendor/bundle
/log/*
/tmp/*
/db/*.sqlite3
/public/system/*
/coverage/
/spec/tmp/*
**.orig
rerun.txt
pickle-email-*.html
.project
config/initializers/secret_token.rb
*.gem
/test/*

.ruby-version
.ruby-gemset

*.swp
*.swo

spec/dummy/db/*.sqlite3
spec/dummy/log/*.log
spec/dummy/tmp/
tags

.byebug_history

```

# spec/spec_helper.rb

```rb
require 'capybara/rspec'
require 'capybara-webkit'

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause this
# file to always be loaded, without a need to explicitly require it in any files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, make a
# separate helper file that requires this one and then use it only in the specs
# that actually need it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    # config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = :expect
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = true
  end
end

Capybara.javascript_driver = :webkit

```

# spec/rails_helper.rb

```rb
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include WaitForAjax, type: :feature

  config.before :each do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

DatabaseCleaner.strategy = :truncation

```

# lib/smart_listing.rb

```rb
require 'smart_listing/config'
require "smart_listing/engine"
require "kaminari"

# Fix parsing nested params
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for @params.deep_merge(page_param(page)).merge(:only_path => true)
      end

      private

      def page_param(page)
        Rack::Utils.parse_nested_query("#{@param_name}=#{page <= 1 ? nil : page}").symbolize_keys
      end
    end
  end
end

module SmartListing
  class Base
    attr_reader :name, :collection, :options, :per_page, :sort, :page, :partial, :count, :params
    # Params that should not be visible in pagination links (pages, per-page, sorting, etc.)
    UNSAFE_PARAMS = [:authenticity_token, :commit, :utf8, :_method, :script_name].freeze
    # For fast-check, like:
    #   puts variable if ALLOWED_DIRECTIONS[variable]
    ALLOWED_DIRECTIONS = Hash[['asc', 'desc', ''].map { |d| [d, true] }].freeze
    private_constant :ALLOWED_DIRECTIONS

    def initialize name, collection, options = {}
      @name = name

      config_profile = options.delete(:config_profile)

      @options = {
        :partial                        => @name,                       # SmartListing partial name
        :sort_attributes                => :implicit,                   # allow implicitly setting sort attributes
        :default_sort                   => {},                          # default sorting
        :href                           => nil,                         # set SmartListing target url (in case when different than current url)
        :remote                         => true,                        # SmartListing is remote by default
        :callback_href                  => nil,                         # set SmartListing callback url (in case when different than current url)
      }.merge(SmartListing.config(config_profile).global_options).merge(options)

      if @options[:array]
        @collection = collection.to_a
      else
        @collection = collection
      end
    end

    def setup params, cookies
      @params = params
      @params = @params.to_unsafe_h if @params.respond_to?(:to_unsafe_h)
      @params = @params.with_indifferent_access
      @params.except!(*UNSAFE_PARAMS)

      @page = get_param :page
      @per_page = !get_param(:per_page) || get_param(:per_page).empty? ? (@options[:memorize_per_page] && get_param(:per_page, cookies).to_i > 0 ? get_param(:per_page, cookies).to_i : page_sizes.first) : get_param(:per_page).to_i
      @per_page = page_sizes.first unless page_sizes.include?(@per_page) || (unlimited_per_page? && @per_page == 0)

      @sort = parse_sort(get_param(:sort)) || @options[:default_sort]
      sort_keys = (@options[:sort_attributes] == :implicit ? @sort.keys.collect{|s| [s, s]} : @options[:sort_attributes])

      set_param(:per_page, @per_page, cookies) if @options[:memorize_per_page]

      @count = @collection.size
      @count = @count.length if @count.is_a?(Hash)

      # Reset @page if greater than total number of pages
      if @per_page > 0
        no_pages = (@count.to_f / @per_page.to_f).ceil.to_i
        if @page.to_i > no_pages
          @page = no_pages
        end
      end

      if @options[:array]
        if @sort && !@sort.empty? # when array we sort only by first attribute
          i = sort_keys.index{|x| x[0] == @sort.to_h.first[0]}
          @collection = @collection.sort do |x, y|
            xval = x
            yval = y
            sort_keys[i][1].split(".").each do |m|
              xval = xval.try(m)
              yval = yval.try(m)
            end
            xval = xval.upcase if xval.is_a?(String)
            yval = yval.upcase if yval.is_a?(String)

            if xval.nil? || yval.nil?
              xval.nil? ? 1 : -1
            else
              if @sort.to_h.first[1] == "asc"
                (xval <=> yval) || (xval && !yval ? 1 : -1)
              else
                (yval <=> xval) || (yval && !xval ? 1 : -1)
              end
            end
          end
        end
        if @options[:paginate] && @per_page > 0
          @collection = ::Kaminari.paginate_array(@collection).page(@page).per(@per_page)
          if @collection.length == 0
            @collection = @collection.page(@collection.total_pages)
          end
        end
      else
        # let's sort by all attributes
        #
        @collection = @collection.order(sort_keys.collect{|s| Arel.sql("#{s[1]} #{@sort[s[0]]}") if @sort[s[0]]}.compact) if @sort && !@sort.empty?

        if @options[:paginate] && @per_page > 0
          @collection = @collection.page(@page).per(@per_page)
        end
      end
    end

    def partial
      @options[:partial]
    end

    def param_names
      @options[:param_names]
    end

    def param_name key
      "#{base_param}[#{param_names[key]}]"
    end

    def unlimited_per_page?
      !!@options[:unlimited_per_page]
    end

    def max_count
      @options[:max_count]
    end

    def href
      @options[:href]
    end

    def callback_href
      @options[:callback_href]
    end

    def remote?
      @options[:remote]
    end

    def page_sizes
      @options[:page_sizes]
    end

    def kaminari_options
      @options[:kaminari_options]
    end

    def sort_dirs
      @options[:sort_dirs]
    end

    def all_params overrides = {}
      ap = {base_param => {}}
      @options[:param_names].each do |k, v|
        if overrides[k]
          ap[base_param][v] = overrides[k]
        else
          ap[base_param][v] = self.send(k)
        end
      end
      ap
    end

    def sort_order attribute
      @sort && @sort[attribute].present? ? @sort[attribute] : nil
    end

    def base_param
      "#{name}_smart_listing"
    end

    private

    def get_param key, store = @params
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"]
      else
        store[base_param].try(:[], param_names[key])
      end
    end

    def set_param key, value, store = @params
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"] = value
      else
        store[base_param] ||= {}
        store[base_param][param_names[key]] = value
      end
    end

    def parse_sort sort_params
      sort = nil

      if @options[:sort_attributes] == :implicit
        return sort if sort_params.blank?

        sort_params.map do |attr, dir|
          key = attr.to_s if @options[:array] || @collection.klass.attribute_method?(attr)
          if key && ALLOWED_DIRECTIONS[dir.to_s]
            sort ||= {}
            sort[key] = dir.to_s
          end
        end
      elsif @options[:sort_attributes]
        @options[:sort_attributes].each do |a|
          k, v = a
          if sort_params && sort_params[k.to_s]
            dir = sort_params[k.to_s].to_s

            if ALLOWED_DIRECTIONS[dir]
              sort ||= {}
              sort[k] = dir.to_s
            end
          end
        end
      end

      sort
    end
  end
end

```

# config/routes.rb

```rb
SmartListing::Engine.routes.draw do
end

```

# .ruby-lsp/main_lockfile_hash

```
8a04408ac42e65f6a835531c998275f89aa8874c12b55da04d9affc2d6b55628
```

# .ruby-lsp/Gemfile

```
# This custom gemfile is automatically generated by the Ruby LSP.
# It should be automatically git ignored, but in any case: do not commit it to your repository.

eval_gemfile(File.expand_path("../Gemfile", __dir__))
gem "ruby-lsp", require: false, group: :development
gem "debug", require: false, group: :development, platforms: :mri
```

# .ruby-lsp/.gitignore

```
*
```

# spec/lib/smart_listing_spec.rb

```rb
require 'rails_helper'

module SmartListing
  describe Base do
    describe '#per_page' do

      context "when there is no specification in params or cookies" do
        it 'take first value in the page sizes' do
          options = { page_sizes: [1] }
          list = build_list(options: options)

          list.setup({}, {})

          expect(list.per_page).to eq 1
        end
      end

      context 'when a value is in params' do
        context 'when the value is in the list of page_sizes' do
          it 'set the per_page as in the value' do
            options = { page_sizes: [1, 2] }
            list = build_list(options: options)

            list.setup({ "users_smart_listing" => { per_page: "2" } }, {})

            expect(list.per_page).to eq 2
          end
        end

        context 'when the value is not in the list of page_sizes' do
          it 'take first value in the page sizes' do
            options = { page_sizes: [1, 2] }
            list = build_list(options: options)

            list.setup({ "users_smart_listing" => { per_page: "3" } }, {})

            expect(list.per_page).to eq 1
          end
        end
      end

      context 'when a value is in cookies' do
        context 'when the memorization is enabled' do
          it 'set the value in the cookies' do
            options = { page_sizes: [1, 2], memorize_per_page: true }
            list = build_list(options: options)

            list.setup({}, { "users_smart_listing" => { per_page: "2" } })

            expect(list.per_page).to eq 2
          end
        end

        context 'when the memorization is disabled' do
          it 'take first value in the page sizes' do
            options = { page_sizes: [1, 2], memorize_per_page: false }
            list = build_list(options: options)

            list.setup({}, { "users_smart_listing" => { per_page: "2" } })

            expect(list.per_page).to eq 1
          end
        end
      end

      context 'when the per page value is at 0' do
        context 'when the unlimited per page option is enabled' do
          it 'set the per page at 0' do
            options = { page_sizes: [1, 2], unlimited_per_page: true }
            list = build_list(options: options)

            list.setup({ "users_smart_listing" => { per_page: "0" } }, {})

            expect(list.per_page).to eq 0
          end
        end

        context 'when the unlimited per page option is disabled' do
          it 'take first value in the page sizes' do
            options = { page_sizes: [1, 2], unlimited_per_page: false }
            list = build_list(options: options)

            list.setup({}, {})

            expect(list.per_page).to eq 1
          end
        end
      end

      context 'when the memorization of per page is enabled' do
        it 'save the perpage in the cookies' do
          options = { page_sizes: [1], memorize_per_page: true }
          list = build_list(options: options)
          cookies = {}

          list.setup({}, cookies)

          expect(cookies["users_smart_listing"][:per_page]).to eq 1
        end
      end
    end

    describe '#sort' do
      context 'with :implicit attributes' do
        context 'when there is a value in params' do
          it 'set sort with the given value' do
            list = build_list
            params = { "users_smart_listing" => { sort: { "name" => "asc" } } }

            list.setup(params, {})

            expect(list.sort).to eq 'name' => 'asc'
            expect(list.collection.order_values).to match_array(['name asc'])
          end

          it 'set sort with the given value without direction' do
            list = build_list
            params = { 'users_smart_listing' => { sort: { 'name' => '' } } }

            list.setup(params, {})

            expect(list.sort).to eq 'name' => ''
            expect(list.collection.order_values).to match_array(['name '])
          end

          it 'does not set sort with the unknown given value' do
            list = build_list
            params = { 'users_smart_listing' => { sort: { 'login' => '' } } }

            list.setup(params, {})

            expect(list.sort).to eq({})
            expect(list.collection.order_values).to match_array([])
          end

          it 'does not set sort with the given value with unknown direction' do
            list = build_list
            params = { 'users_smart_listing' => { sort: { 'name' => 'dasc' } } }

            list.setup(params, {})

            expect(list.sort).to eq({})
            expect(list.collection.order_values).to match_array([])
          end
        end

        context 'when there is no value in params' do
          it 'take the value in options' do
            options = { default_sort: { 'email' => 'asc' } }
            list = build_list(options: options)

            list.setup({}, {})

            expect(list.sort).to eq 'email' => 'asc'
            expect(list.collection.order_values).to match_array(['email asc'])
          end
        end
      end

      context 'with sort_attributes' do
        context 'when there is a value in params' do
          it 'set sort with the given value' do
            options = { sort_attributes: [[:username, 'users.name']] }
            list = build_list(options: options)
            params = { 'users_smart_listing' => { sort: { 'username' => 'asc' } } }

            list.setup(params, {})

            expect(list.sort).to eq username: 'asc'
            expect(list.collection.order_values).to match_array(['users.name asc'])
          end

          it 'set sort with the given value without direction' do
            options = { sort_attributes: [[:username, 'users.name']] }
            list = build_list(options: options)
            params = { 'users_smart_listing' => { sort: { 'username' => '' } } }

            list.setup(params, {})

            expect(list.sort).to eq username: ''
            expect(list.collection.order_values).to match_array(['users.name '])
          end

          it 'does not set sort with the unknown given value' do
            options = { sort_attributes: [[:username, 'users.name']] }
            list = build_list(options: options)
            params = { 'users_smart_listing' => { sort: { 'login' => 'asc' } } }

            list.setup(params, {})

            expect(list.sort).to eq({})
            expect(list.collection.order_values).to match_array([])
          end

          it 'does not set sort with the given value with unknown direction' do
            options = { sort_attributes: [[:username, 'users.name']] }
            list = build_list(options: options)
            params = { 'users_smart_listing' => { sort: { 'username' => 'dasc' } } }

            list.setup(params, {})

            expect(list.sort).to eq({})
            expect(list.collection.order_values).to match_array([])
          end
        end

        context 'when there is no value in params' do
          it 'take the value in options' do
            options = { default_sort: { username: 'desc' }, sort_attributes: [[:username, 'users.name']] }
            list = build_list(options: options)

            list.setup({}, {})

            expect(list.sort).to eq username: 'desc'
            expect(list.collection.order_values).to match_array(['users.name desc'])
          end
        end
      end
    end

    describe '#page' do
      context 'when the page is in the range' do
        it 'set the value with the given params' do
          User.create
          User.create
          options = { page_sizes: [1] }
          list = build_list(options: options)

          list.setup({ "users_smart_listing" => { page: 2 } }, {})

          expect(list.page).to eq 2
        end
      end

      context 'when the page is out of range' do
        it 'set the value to the last page' do
          User.create
          User.create
          options = { page_sizes: [1] }
          list = build_list(options: options)

          list.setup({ "users_smart_listing" => { page: 3 } }, {})

          expect(list.page).to eq 2
        end
      end
    end

    describe '#collection' do
      context 'when the collection is an array' do
        it 'sort the collection by the first attribute' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { array: true }
          list = build_list(options: options)

          params = { "users_smart_listing" => { sort: { "name" => "desc" } } }
          list.setup(params, {})

          expect(list.collection.first).to eq user2
          expect(list.collection.last).to eq user1
        end

        it 'give only the given number per page' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { page_sizes: [1], array: true }
          list = build_list(options: options)

          list.setup({},{})

          expect(list.collection).to include user1
          expect(list.collection).to_not include user2
        end

        it 'give the right page' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { page_sizes: [1], array: true }
          list = build_list(options: options)

          list.setup({ "users_smart_listing" => { page: 2 } }, {})

          expect(list.collection).to include user2
          expect(list.collection).to_not include user1
        end
      end

      context 'when the collection is not an array' do
        it 'sort the collection by the given option' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { default_sort: { 'name' => 'desc' } }
          list = build_list(options: options)

          list.setup({},{})

          expect(list.collection.first).to eq user2
          expect(list.collection.last).to eq user1
        end

        it 'give only the given number per page' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { page_sizes: [1] }
          list = build_list(options: options)

          list.setup({},{})

          expect(list.collection).to include user1
          expect(list.collection).to_not include user2
        end

        it 'give the right page' do
          user1 = User.create(name: '1')
          user2 = User.create(name: '2')
          options = { page_sizes: [1] }
          list = build_list(options: options)

          list.setup({ "users_smart_listing" => { page: 2 } }, {})

          expect(list.collection).to include user2
          expect(list.collection).to_not include user1
        end
      end
    end

    def build_list(options: {})
      Base.new(:users, User.all, options)
    end
  end
end

```

# spec/features/view_items_spec.rb

```rb
require 'rails_helper'

feature 'View a list of items' do
  fixtures :users
  scenario 'The user navigate through users', js: true do

    visit root_path
    #page_sizes => [3, 10]
    expect(page).to have_content("Betty")
    expect(page).to_not have_content("Edward")

    within(".pagination") { click_on "2" }

    expect(page).to have_content("Edward")
    expect(page).to_not have_content("Betty")
  end

  scenario "The user sort users", js: true do

    visit sortable_users_path

    find('.name a').click
    expect(find(:xpath, "//table/tbody/tr[1]")).to have_content("Aaron")
    expect(find(:xpath, "//table/tbody/tr[2]")).to have_content("Betty")

    find('.name a').click
    expect(find(:xpath, "//table/tbody/tr[1]")).to have_content("Sara")
    expect(find(:xpath, "//table/tbody/tr[2]")).to have_content("Robin")
  end

  scenario "The user search user", js: true do
    visit admin_users_path

    fill_in "filter", with: "ja"

    expect(page).to have_content("Jane")
    expect(page).to_not have_content("Aaron")

    fill_in "filter", with: "ni"

    expect(page).to_not have_content("Nicholas")
    expect(page).to_not have_content("Jane")
  end
end

```

# spec/features/manage_items_spec.rb

```rb
require 'rails_helper'

feature "Manage items" do
  scenario "Add a new item", js: true do
    visit admin_users_path

    click_on "New item"
    fill_in "Name", with: "Test name"
    fill_in "Email", with: "Test email"
    click_on "Save"

    expect(page).to have_content("Test name")
  end

  scenario "Edit an item", js: true do
    User.create(name: "Name 1", email: "Email 1")
    visit admin_users_path

    find('.edit').click
    fill_in "Name", with: "Name 2"
    fill_in "Email", with: "Email 2"
    click_on "Save"

    expect(page).to have_content("Name 2")
    expect(page).to_not have_content("Name 1")
  end

  scenario "Delete an item", js: true do
    User.create(name: "Name 1", email: "Email 1")

    visit admin_users_path
    find('.destroy').click
    within('.confirmation_box') { click_on "Yes" }

    expect(page).to_not have_content("Name 1")
  end

  scenario "Use a custom action", js: true do
    User.create(name: "Name 1", email: "Email 1")

    visit admin_users_path
    find('.change_name').click

    expect(page).to have_content("Changed Name")
  end
end

```

# spec/features/custom_filters_spec.rb

```rb
require 'rails_helper'

feature 'Combine custom filtering' do
  fixtures :users

  scenario 'The user search user, change pagination and change page', js: true do

    visit admin_users_path
    #page_sizes => [3, 10]
    within(".pagination-per-page") { click_on "10" }
    expect(page).to have_selector('tr.editable', count: 8)
    fill_in "filter", with: "test"
    expect(page).to have_selector('tr.editable', count: 4)
    within(".pagination-per-page") { click_on "3" }
    within(".pagination") { click_on "2" }
    expect(page).to have_selector('tr.editable', count: 1)

  end

  scenario 'The user sort users and change page', js: true do

    visit admin_users_path
    find('.name a.sortable').click
    expect(page).to have_content("Aaron")
    expect(page).to_not have_content("Jane")
    within(".pagination") { click_on "2" }
    expect(page).to have_content("Jane")
    expect(page).to_not have_content("Aaron")

  end

  scenario 'The user combine filters', js: true do

    visit admin_users_path
    fill_in "filter", with: "email"
    find('input#boolean').click
    expect(page).to have_selector('tr.editable', count: 2)

  end

  scenario 'The user combine filters and sort users', js: true do

    visit admin_users_path
    fill_in "filter", with: "test"
    find('input#boolean').click
    wait_for_ajax
    expect(page).to have_selector('tr.editable', count: 2)
    click_link 'Name'
    expect(page).to have_selector('tr.editable', count: 2)
    expect(page.find(:css, "tbody > tr:nth-child(1)")).to have_content("Edward")
    expect(page.find(:css, "tbody > tr:nth-child(2)")).to have_content("Robin")

  end

  scenario 'The user combine filters, sort and change page', js: true do

    visit admin_users_path
    check 'boolean'
    wait_for_ajax
    expect(find(:css, '.email a.sortable')[:href]).to include("boolean")
    click_link 'Email'
    expect(page.find(:css, "tbody > tr:nth-child(2)")).to have_content("Lisa")
    within(".pagination") { click_on "2" }
    expect(page.find(:css, "tbody > tr:nth-child(1)")).to have_content("Robin")
    expect(page.find(:css, '.count')).to have_content("4")

  end

end

```

# spec/dummy/config.ru

```ru
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

```

# spec/dummy/Rakefile

```
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

```

# spec/dummy/README.rdoc

```rdoc
== README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.

```

# spec/dummy/Gemfile

```
source "https://rubygems.org"

gemspec path: "../.."

```

# lib/tasks/smart_list_tasks.rake

```rake
# desc "Explaining what the task does"
# task :smart_list do
#   # Task goes here
# end

```

# lib/smart_listing/version.rb

```rb
module SmartListing
  VERSION = "1.2.3"
end

```

# lib/smart_listing/engine.rb

```rb
module SmartListing
  class Engine < ::Rails::Engine
    isolate_namespace SmartListing
  end
end

```

# lib/smart_listing/config.rb

```rb
module SmartListing
  mattr_reader :configs

  def self.configure profile = nil
    profile ||= :default
    @@configs ||= {}
    yield @@configs[profile] ||= SmartListing::Configuration.new
  end

  def self.config profile = nil
    profile ||= :default
    @@configs ||= {}
    @@configs[profile] ||= SmartListing::Configuration.new
  end

  class Configuration
    DEFAULT_PAGE_SIZES = [10, 20, 50, 100].freeze

    DEFAULTS = {
      :global_options => {
        :param_names  => {                                      # param names
          :page                         => :page,
          :per_page                     => :per_page,
          :sort                         => :sort,
        },
        :array                          => false,                       # controls whether smart list should be using arrays or AR collections
        :max_count                      => nil,                         # limit number of rows
        :unlimited_per_page             => false,                       # allow infinite page size
        :paginate                       => true,                        # allow pagination
        :memorize_per_page              => false,
        :page_sizes                     => DEFAULT_PAGE_SIZES.dup,      # set available page sizes array
        :kaminari_options               => {:theme => "smart_listing"}, # Kaminari's paginate helper options
        :sort_dirs                      => [nil, "asc", "desc"],        # Default sorting directions cycle of sortables
        :remote                         => true,                        # Default remote mode
      },
      :constants => {
        :classes => {
          :main => "smart-listing",
          :editable => "editable",
          :content => "content",
          :loading => "loading",
          :status => "smart-listing-status",
          :item_actions => "actions",
          :new_item_placeholder => "new-item-placeholder",
          :new_item_action => "new-item-action",
          :new_item_button => "btn",
          :hidden => "hidden",
          :autoselect => "autoselect",
          :callback => "callback",
          :pagination_wrapper => "text-center",
          :pagination_container => "pagination",
          :pagination_per_page => "pagination-per-page text-center",
          :inline_editing => "info",
          :no_records => "no-records",
          :limit => "smart-listing-limit",
          :limit_alert => "smart-listing-limit-alert",
          :controls => "smart-listing-controls",
          :controls_reset => "reset",
          :filtering => "filter",
          :filtering_search => "glyphicon-search",
          :filtering_cancel => "glyphicon-remove",
          :filtering_disabled => "disabled",
          :sortable => "sortable",
          :icon_new => "glyphicon glyphicon-plus",
          :icon_edit => "glyphicon glyphicon-pencil",
          :icon_trash => "glyphicon glyphicon-trash",
          :icon_inactive => "glyphicon glyphicon-remove-circle text-muted",
          :icon_show => "glyphicon glyphicon-share-alt",
          :icon_sort_none => "glyphicon glyphicon-resize-vertical",
          :icon_sort_up => "glyphicon glyphicon-chevron-up",
          :icon_sort_down => "glyphicon glyphicon-chevron-down",
          :muted => "text-muted",
        },
        :data_attributes => {
          :main => "smart-listing",
          :controls_initialized => "smart-listing-controls-initialized",
          :confirmation => "confirmation",
          :id => "id",
          :href => "href",
          :callback_href => "callback-href",
          :max_count => "max-count",
          :item_count => "item-count",
          :inline_edit_backup => "smart-listing-edit-backup",
          :params => "params",
          :observed => "observed",
          :autoshow => "autoshow",
          :popover => "slpopover",
        },
        :selectors => {
          :item_action_destroy => "a.destroy",
          :edit_cancel => "button.cancel",
          :row => "tr",
          :head => "thead",
          :filtering_button => "button",
          :filtering_icon => "button span",
          :filtering_input => ".filter input",
          :pagination_count => ".pagination-per-page .count",
        },
        :element_templates => {
          :row => "<tr />",
        },
        :bootstrap_commands => {
          :popover_destroy => "destroy",
        }
      }
    }.freeze

    attr_reader :options

    def initialize
      @options = {}
    end

    def method_missing(sym, *args, &block)
      @options[sym] = *args
    end
    
    def constants key, value = nil
      if value && !value.empty?
        @options[:constants] ||= {}
        @options[:constants][key] ||= {}
        @options[:constants][key].merge!(value)
      end
      @options[:constants].try(:[], key) || DEFAULTS[:constants][key]
    end

    def classes key
      @options[:constants].try(:[], :classes).try(:[], key) || DEFAULTS[:constants][:classes][key]
    end

    def data_attributes key
      @options[:constants].try(:[], :data_attributes).try(:[], key) || DEFAULTS[:constants][:data_attributes][key]
    end

    def selectors key
      @options[:constants].try(:[], :selectors).try(:[], key) || DEFAULTS[:constants][:selectors][key]
    end

    def element_templates key
      @options[:constants].try(:[], :element_templates).try(:[], key) || DEFAULTS[:constants][:element_templates][key]
    end

    def global_options value = nil
      if value && !value.empty?
        @options[:global_options] ||= {}
        @options[:global_options].merge!(value)
      end
      !@options[:global_options] ? DEFAULTS[:global_options] : DEFAULTS[:global_options].deep_merge(@options[:global_options])
    end
    
    def to_json
      @options.to_json
    end

    def dump
      DEFAULTS.deep_merge(@options)
    end

    def dump_json
      dump.to_json
    end
  end
end

```

# config/locales/en.yml

```yml
en:
  smart_listing:
    msgs:
      destroy_confirmation: Destroy?
      no_items: No items
    actions:
      destroy: Destroy
      edit: Edit
      show: Show
      new: New item
  views:
    pagination:
      per_page: Per page
      unlimited: Unlimited
      total: Total

```

# spec/support/capybara/wait_for_ajax.rb

```rb
module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end

```

# spec/helpers/smart_listing/helper_spec.rb

```rb
require 'rails_helper'
require 'smart_listing/helper'

module SmartListing::Helper
  class UsersController < ApplicationController
    include ControllerExtensions
    helper  SmartListing::Helper

    attr_accessor :smart_listings

    def params
      { value: 'params' }
    end

    def cookies
      { value: 'cookies' }
    end

    def smart_listing_collection
      [1, 2]
    end
  end

  describe ControllerExtensions do
    describe "#smart_listing_create" do
      it "create a list with params and cookies" do
        controller = UsersController.new
        list = build_list

        expect(list).to receive(:setup).with(controller.params,
                                             controller.cookies)

        controller.smart_listing_create
      end

      it "assign a list in smart listings with the name" do
        controller = UsersController.new
        list = build_list

        controller.smart_listing_create

        expect(controller.smart_listings[:users]).to eq list
      end

      it 'return the collection of the list' do
        controller = UsersController.new
        collection1 = double
        collection2 = double
        build_list(collection: collection1)

        controller.smart_listing_create(collection: collection2)

        actual = controller.smart_listings[:users].collection
        expect(actual).to eq collection1
      end

      def build_list(collection: {})
        double(collection: collection, setup: nil).tap do |list|
          allow(SmartListing::Base).to receive(:new).and_return(list)
        end
      end
    end

    describe '#smart_listing' do
      it 'give the list with name' do
        controller = UsersController.new
        list = double
        controller.smart_listings = { test: list }
        expect(controller.smart_listing(:test)).to eq list
      end
    end
  end
end

```

# spec/dummy/public/favicon.ico

```ico

```

# spec/dummy/public/500.html

```html
<!DOCTYPE html>
<html>
<head>
  <title>We're sorry, but something went wrong (500)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
  body {
    background-color: #EFEFEF;
    color: #2E2F30;
    text-align: center;
    font-family: arial, sans-serif;
    margin: 0;
  }

  div.dialog {
    width: 95%;
    max-width: 33em;
    margin: 4em auto 0;
  }

  div.dialog > div {
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #BBB;
    border-top: #B00100 solid 4px;
    border-top-left-radius: 9px;
    border-top-right-radius: 9px;
    background-color: white;
    padding: 7px 12% 0;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }

  h1 {
    font-size: 100%;
    color: #730E15;
    line-height: 1.5em;
  }

  div.dialog > p {
    margin: 0 0 1em;
    padding: 1em;
    background-color: #F7F7F7;
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #999;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    border-top-color: #DADADA;
    color: #666;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }
  </style>
</head>

<body>
  <!-- This file lives in public/500.html -->
  <div class="dialog">
    <div>
      <h1>We're sorry, but something went wrong.</h1>
    </div>
    <p>If you are the application owner check the logs for more information.</p>
  </div>
</body>
</html>

```

# spec/dummy/public/422.html

```html
<!DOCTYPE html>
<html>
<head>
  <title>The change you wanted was rejected (422)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
  body {
    background-color: #EFEFEF;
    color: #2E2F30;
    text-align: center;
    font-family: arial, sans-serif;
    margin: 0;
  }

  div.dialog {
    width: 95%;
    max-width: 33em;
    margin: 4em auto 0;
  }

  div.dialog > div {
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #BBB;
    border-top: #B00100 solid 4px;
    border-top-left-radius: 9px;
    border-top-right-radius: 9px;
    background-color: white;
    padding: 7px 12% 0;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }

  h1 {
    font-size: 100%;
    color: #730E15;
    line-height: 1.5em;
  }

  div.dialog > p {
    margin: 0 0 1em;
    padding: 1em;
    background-color: #F7F7F7;
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #999;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    border-top-color: #DADADA;
    color: #666;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }
  </style>
</head>

<body>
  <!-- This file lives in public/422.html -->
  <div class="dialog">
    <div>
      <h1>The change you wanted was rejected.</h1>
      <p>Maybe you tried to change something you didn't have access to.</p>
    </div>
    <p>If you are the application owner check the logs for more information.</p>
  </div>
</body>
</html>

```

# spec/dummy/public/404.html

```html
<!DOCTYPE html>
<html>
<head>
  <title>The page you were looking for doesn't exist (404)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
  body {
    background-color: #EFEFEF;
    color: #2E2F30;
    text-align: center;
    font-family: arial, sans-serif;
    margin: 0;
  }

  div.dialog {
    width: 95%;
    max-width: 33em;
    margin: 4em auto 0;
  }

  div.dialog > div {
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #BBB;
    border-top: #B00100 solid 4px;
    border-top-left-radius: 9px;
    border-top-right-radius: 9px;
    background-color: white;
    padding: 7px 12% 0;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }

  h1 {
    font-size: 100%;
    color: #730E15;
    line-height: 1.5em;
  }

  div.dialog > p {
    margin: 0 0 1em;
    padding: 1em;
    background-color: #F7F7F7;
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #999;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    border-top-color: #DADADA;
    color: #666;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }
  </style>
</head>

<body>
  <!-- This file lives in public/404.html -->
  <div class="dialog">
    <div>
      <h1>The page you were looking for doesn't exist.</h1>
      <p>You may have mistyped the address or the page may have moved.</p>
    </div>
    <p>If you are the application owner check the logs for more information.</p>
  </div>
</body>
</html>

```

# spec/dummy/log/.keep

```

```

# spec/dummy/fixtures/users.yml

```yml
user1:
  id: 1
  name: "Betty"
  email: "betty@email.com"
  boolean: false
user2:
  id: 2
  name: "Aaron"
  email: "aaron@email.com"
  boolean: true
user3:
  id: 3
  name: "Jane"
  email: "jane@test.eu"
  boolean: false
user4:
  id: 4
  name: "Edward"
  email: "edward@test.eu"
  boolean: true
user5:
  id: 5
  name: "Nicholas"
  email: "salohcin@email.com"
  boolean: false
user6:
  id: 6
  name: "Lisa"
  email: "asil@email.com"
  boolean: true
user7:
  id: 7
  name: "Sara"
  email: "aras@test.eu"
  boolean: false
user8:
  id: 8
  name: "Robin"
  email: "nibor@test.eu"
  boolean: true

```

# spec/dummy/db/seeds.rb

```rb
User.find_or_create_by(id: 1, name: "Betty", email: "betty@email.com", boolean: false)
User.find_or_create_by(id: 2, name: "Aaron", email: "aaron@email.com", boolean: true)
User.find_or_create_by(id: 3, name: "Jane", email: "jane@test.eu", boolean: false)
User.find_or_create_by(id: 4, name: "Edward", email: "edward@test.eu", boolean: true)
User.find_or_create_by(id: 5, name: "Nicholas", email: "salohcin@email.com", boolean: false)
User.find_or_create_by(id: 6, name: "Lisa", email: "asil@email.com", boolean: true)
User.find_or_create_by(id: 7, name: "Sara", email: "aras@test.eu", boolean: false)
User.find_or_create_by(id: 8, name: "Robin", email: "nibor@test.eu", boolean: true)

```

# spec/dummy/db/schema.rb

```rb
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180126065408) do

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.boolean "boolean"
  end

end

```

# spec/dummy/config/secrets.yml

```yml
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure the secrets in this file are kept private
# if you're sharing your code publicly.

development:
  secret_key_base: cb71bf666c97336b3d87e2aaf8b4fc962264491f7eadaf838f8ef290d115631b7a640c9a60704e9c3a110692d06cd105e87c4cd5591d659c3ce44c7b5128ec18

test:
  secret_key_base: f3ab27e4cd06e477d716bce701634636d2db5b835592dde50e7e64fa59adef9db7fce71c7b7bfe581089280a6f0e39e67a0efeae559a3f89e7138a44b9fda4a1

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>

```

# spec/dummy/config/routes.rb

```rb
Rails.application.routes.draw do
  resources :users do
    collection do
      get 'sortable'
      get 'searchable'
    end
  end

  namespace :admin do
    resources :users do
      member do
        put 'change_name'
      end
    end
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'users#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

```

# spec/dummy/config/environment.rb

```rb
# Load the Rails application.
require File.expand_path('../application', __FILE__)

require "jquery-rails"
require 'coffee-rails'
require 'bootstrap-sass'

# Initialize the Rails application.
Rails.application.initialize!

```

# spec/dummy/config/database.yml

```yml
# SQLite version 3.x
#   gem install sqlite3
#
#   Ensure the SQLite 3 gem is defined in your Gemfile
#   gem 'sqlite3'
#
default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: db/test.sqlite3

production:
  <<: *default
  database: db/production.sqlite3

```

# spec/dummy/config/boot.rb

```rb
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
$LOAD_PATH.unshift File.expand_path('../../../../lib', __FILE__)

```

# spec/dummy/config/application.rb

```rb
require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "smart_listing"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end


```

# lib/generators/smart_listing/views_generator.rb

```rb
module SmartListing
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../app/views/smart_listing', __FILE__)

      def self.banner #:nodoc:
        <<-BANNER.chomp
rails g smart_listing:views

    Copies all smart listing partials templates to your application.
BANNER
      end

      desc ''
      def copy_views
        filename_pattern = File.join self.class.source_root, "*.html.erb"
        Dir.glob(filename_pattern).map {|f| File.basename f}.each do |f|
          copy_file f, "app/views/smart_listing/#{f}"
        end
      end
    end
  end
end

```

# lib/generators/smart_listing/install_generator.rb

```rb
module SmartListing
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def self.banner #:nodoc:
        <<-BANNER.chomp
rails g smart_listing:install

    Copies initializer file
BANNER
      end

      desc ''
      def copy_views
        template 'initializer.rb', 'config/initializers/smart_listing.rb'
      end
    end
  end
end

```

# app/views/smart_listing/update.js.erb

```erb
<%= smart_listing_item :update, smart_listing_resource,
  smart_listing_resource.valid? ? "item" : "form" %>

```

# app/views/smart_listing/new.js.erb

```erb
<%= smart_listing_item :new, smart_listing_resource, "form" %>

```

# app/views/smart_listing/index.js.erb

```erb
<%= smart_listing_update %>

```

# app/views/smart_listing/edit.js.erb

```erb
<%= smart_listing_item :edit, smart_listing_resource, "form" %>

```

# app/views/smart_listing/destroy.js.erb

```erb
<%= smart_listing_item :destroy, smart_listing_resource %>

```

# app/views/smart_listing/create.js.erb

```erb
<%= smart_listing_item :create, smart_listing_resource,
  smart_listing_resource.valid? ? "item" : "form" %>

```

# app/views/smart_listing/_update_list.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.update_list("<%= escape_javascript(render(:partial => part, :locals => {:smart_listing => smart_listing}.merge(locals))) %>", <%= smart_listing_data.to_json.html_safe %>);

```

# app/views/smart_listing/_sortable.html.erb

```erb
<%# 
  Sortable attribute listing header.

  Available local variables:
    container_classes:  classes for the main container
    url:                sortable link url
    attribute:          current attribute name
    title:              current attribute title
    order:              defines column sort order
    smart_listing:      current SmartListing instance
    builder:            current builder instance
-%>

<%= link_to url, :class => container_classes, :data => {:attr => attribute}, :remote => remote do %>
  <%= title %>
  <% if order %>
    <span class="<%= order == "asc" ? smart_listing_config.classes(:icon_sort_up) : smart_listing_config.classes(:icon_sort_down) %>"></span>
  <% else %>
    <span class="<%= smart_listing_config.classes(:icon_sort_none) %>"></span>
  <% end %>
<% end %>

```

# app/views/smart_listing/_pagination_per_page_links.html.erb

```erb
<%# 
  Pagination per-page links.

  Available local variables:
    container_classes:  classes for the main container
    per_page_sizes:     array of available per-page sizes
    smart_listing:      current SmartListing instance
    builder:            current builder instance
-%>

<%= content_tag(:div, :class => container_classes ) do %>
  <% if smart_listing.options[:paginate] && (smart_listing.count > smart_listing.page_sizes.first) %>
    <%= t('views.pagination.per_page') %>
    <% per_page_sizes.each do |p| %><%= builder.pagination_per_page_link p %><% break if p >= smart_listing.count %><% end %>
    |
  <% end %>
  <%= t('views.pagination.total') %>
  <%= content_tag(:span, smart_listing.count, :class => "count") %>
<% end %>

```

# app/views/smart_listing/_pagination_per_page_link.html.erb

```erb
<%# 
  Pagination single per-page link.

  Available local variables:
    page:           page number
    url:            page url (if page is not selected)
    smart_listing:  current SmartListing instance
    builder:        current builder instance
-%>

<% name = page == 0 ? t('views.pagination.unlimited') : page %>
<%= url ? link_to(name, url, :remote => smart_listing.remote?) : content_tag(:span, name) %>

```

# app/views/smart_listing/_item_new.html.erb

```erb
<%# 
  New list item element (contains new item placeholder and add button).

  Available local variables:
    placeholder_classes:      classes for the main container
    new_item_action_classes:  new item action classes
    colspan              
    no_items_classes:         no items container classes
    no_items_text:            no items text displayed inside container
    new_item_button_url:      argument to link_to (new item button)
    new_item_button_classes
    new_item_button_text
    new_item_autoshow         automatically show new item placeholder
    new_item_content          new item placeholder content (usually some form)
-%>

<%= content_tag(:tr, '', :class => placeholder_classes + %w{info}, :data => {smart_listing_config.data_attributes(:autoshow) => new_item_autoshow}) do %>
  <%= new_item_content %>
<% end %>
<%= content_tag(:tr, :class => new_item_action_classes + %w{info}) do %>
  <%= content_tag(:td, :colspan => colspan) do %>
    <%= content_tag(:p, :class => no_items_classes + %w{pull-left}) do %>
      <%= no_items_text %>
    <% end %>
    <%= link_to(new_item_button_url, :remote => true, :class => new_item_button_classes + %w{btn pull-right}) do %>
      <%= content_tag(:i, '', :class => smart_listing_config.classes(:icon_new)) %>
      <%= new_item_button_text %>
    <% end %>
  <% end %>
<% end %>

```

# app/views/smart_listing/_action_show.html.erb

```erb
<%# 
  Show action.

  Available local variables:
    action_if:          false if action is disabled
    url:                show url
    icon:               icon clss classes
    title
-%>

<%= link_to_if(action_if, content_tag(:i, '', :class => icon), url, :class => "show", :title => title || t("smart_listing.actions.show") ) %>

```

# app/views/smart_listing/_action_edit.html.erb

```erb
<%# 
  Edit action.

  Available local variables:
    action_if:          false if action is disabled
    url:                edit url
    icon:               icon css classes
    title
-%>

<%= link_to_if(action_if, content_tag(:i, '', :class => icon), url, :remote => true, :class => "edit", :title => title || t("smart_listing.actions.edit") ) %>

```

# app/views/smart_listing/_action_delete.html.erb

```erb
<%# 
  Delete action.

  Available local variables:
    action_if:          false if action is disabled
    url:                destroy url
    icon:               icon css classes
    confirmation:       confrimation text
    title
-%>

<%= link_to_if(action_if, content_tag(:i, "", :class => icon), url, :remote => true, :class => "destroy", :method => :delete, :title => title || t("smart_listing.actions.destroy"), :data => {:confirmation => confirmation || t("smart_listing.msgs.destroy_confirmation")} ) %>

```

# app/views/smart_listing/_action_custom.html.erb

```erb
<%# 
  Custom action.

  Available local variables:
    url
    icon
    html_options:       custom html options
-%>

<%= link_to_if(action_if, content_tag(:span, '', :class => icon, :title => title), url, html_options) %>

```

# app/helpers/smart_listing/helper.rb

```rb
module SmartListing
  module Helper
    module ControllerExtensions
      # Creates new smart listing
      #
      # Possible calls:
      # smart_listing_create name, collection, options = {}
      # smart_listing_create options = {}
      def smart_listing_create *args
        options = args.extract_options!
        name = (args[0] || options[:name] || controller_name).to_sym
        collection = args[1] || options[:collection] || smart_listing_collection

        view_context = self.respond_to?(:controller) ? controller.view_context : self.view_context
        options = {:config_profile => view_context.smart_listing_config_profile}.merge(options)

        list = SmartListing::Base.new(name, collection, options)
        list.setup(params, cookies)

        @smart_listings ||= {}
        @smart_listings[name] = list

        list.collection
      end

      def smart_listing name
        @smart_listings[name.to_sym]
      end

      def _prefixes
        super << 'smart_listing'
      end
    end

    class Builder

      class_attribute :smart_listing_helpers

      def initialize(smart_listing_name, smart_listing, template, options, proc)
        @smart_listing_name, @smart_listing, @template, @options, @proc = smart_listing_name, smart_listing, template, options, proc
      end

      def name
        @smart_listing_name
      end

      def paginate options = {}
        if @smart_listing.collection.respond_to? :current_page
          @template.paginate @smart_listing.collection, **{:remote => @smart_listing.remote?, :param_name => @smart_listing.param_name(:page)}.merge(@smart_listing.kaminari_options)
        end
      end

      def collection
        @smart_listing.collection
      end

      # Check if smart list is empty
      def empty?
        @smart_listing.count == 0
      end

      def pagination_per_page_links options = {}
        container_classes = [@template.smart_listing_config.classes(:pagination_per_page)]
        container_classes << @template.smart_listing_config.classes(:hidden) if empty?

        per_page_sizes = @smart_listing.page_sizes.clone
        per_page_sizes.push(0) if @smart_listing.unlimited_per_page?

        locals = {
          :container_classes => container_classes,
          :per_page_sizes => per_page_sizes,
        }

        @template.render(:partial => 'smart_listing/pagination_per_page_links', :locals => default_locals.merge(locals))
      end

      def pagination_per_page_link page
        if @smart_listing.per_page.to_i != page
          url = @template.url_for(@smart_listing.params.merge(@smart_listing.all_params(:per_page => page, :page => 1)))
        end

        locals = {
          :page => page,
          :url => url,
        }

        @template.render(:partial => 'smart_listing/pagination_per_page_link', :locals => default_locals.merge(locals))
      end

      def sortable title, attribute, options = {}
        dirs = options[:sort_dirs] || @smart_listing.sort_dirs || [nil, "asc", "desc"]

        next_index = dirs.index(@smart_listing.sort_order(attribute)).nil? ? 0 : (dirs.index(@smart_listing.sort_order(attribute)) + 1) % dirs.length

        sort_params = {
          attribute => dirs[next_index]
        }

        locals = {
          :order => @smart_listing.sort_order(attribute),
          :url => @template.url_for(@smart_listing.params.merge(@smart_listing.all_params(:sort => sort_params))),
          :container_classes => [@template.smart_listing_config.classes(:sortable)],
          :attribute => attribute,
          :title => title,
          :remote => @smart_listing.remote?
        }

        @template.render(:partial => 'smart_listing/sortable', :locals => default_locals.merge(locals))
      end

      def update options = {}
        part = options.delete(:partial) || @smart_listing.partial || @smart_listing_name

        @template.render(:partial => 'smart_listing/update_list', :locals => {:name => @smart_listing_name, :part => part, :smart_listing => self})
      end

      # Renders the main partial (whole list)
      def render_list locals = {}
        if @smart_listing.partial
          @template.render :partial => @smart_listing.partial, :locals => {:smart_listing => self}.merge(locals || {})
        end
      end

      # Basic render block wrapper that adds smart_listing reference to local variables
      def render options = {}, locals = {}, &block
        if locals.empty?
          options[:locals] ||= {}
          options[:locals].merge!(:smart_listing => self)
        else
          locals.merge!({:smart_listing => self})
        end

        @template.render options, locals, &block
      end

      # Add new item button & placeholder to list
      def item_new options = {}, &block
        no_records_classes = [@template.smart_listing_config.classes(:no_records)]
        no_records_classes << @template.smart_listing_config.classes(:hidden) unless empty?
        new_item_button_classes = []
        new_item_button_classes << @template.smart_listing_config.classes(:hidden) if max_count?

        locals = {
          :colspan => options.delete(:colspan),
          :no_items_classes => no_records_classes,
          :no_items_text => options.delete(:no_items_text) || @template.t("smart_listing.msgs.no_items"),
          :new_item_button_url => options.delete(:link),
          :new_item_button_classes => new_item_button_classes,
          :new_item_button_text => options.delete(:text) || @template.t("smart_listing.actions.new"),
          :new_item_autoshow => block_given?,
          :new_item_content => nil,
        }

        unless block_given?
          locals[:placeholder_classes] = [@template.smart_listing_config.classes(:new_item_placeholder), @template.smart_listing_config.classes(:hidden)]
          locals[:new_item_action_classes] = [@template.smart_listing_config.classes(:new_item_action)]
          locals[:new_item_action_classes] << @template.smart_listing_config.classes(:hidden) if !empty? && max_count?

          @template.render(:partial => 'smart_listing/item_new', :locals => default_locals.merge(locals))
        else
          locals[:placeholder_classes] = [@template.smart_listing_config.classes(:new_item_placeholder)]
          locals[:placeholder_classes] << @template.smart_listing_config.classes(:hidden) if !empty? && max_count?
          locals[:new_item_action_classes] = [@template.smart_listing_config.classes(:new_item_action), @template.smart_listing_config.classes(:hidden)]

          locals[:new_item_content] = @template.capture(&block)
          @template.render(:partial => 'smart_listing/item_new', :locals => default_locals.merge(locals))
        end
      end

      def count
        @smart_listing.count
      end

      # Check if smart list reached its item max count
      def max_count?
        return false if @smart_listing.max_count.nil?
        @smart_listing.count >= @smart_listing.max_count
      end

      private

      def default_locals
        {:smart_listing => @smart_listing, :builder => self}
      end
    end

    def smart_listing_config_profile
      defined?(super) ? super : :default
    end

    def smart_listing_config
      SmartListing.config(smart_listing_config_profile)
    end

    # Outputs smart list container
    def smart_listing_for name, *args, &block
      raise ArgumentError, "Missing block" unless block_given?
      name = name.to_sym
      options = args.extract_options!
      bare = options.delete(:bare)

      builder = Builder.new(name, @smart_listings[name], self, options, block)

      output = ""

      data = {}
      data[smart_listing_config.data_attributes(:max_count)] = @smart_listings[name].max_count if @smart_listings[name].max_count && @smart_listings[name].max_count > 0
      data[smart_listing_config.data_attributes(:item_count)] = @smart_listings[name].count
      data[smart_listing_config.data_attributes(:href)] = @smart_listings[name].href if @smart_listings[name].href
      data[smart_listing_config.data_attributes(:callback_href)] = @smart_listings[name].callback_href if @smart_listings[name].callback_href
      data.merge!(options[:data]) if options[:data]

      if bare
        output = capture(builder, &block)
      else
        output = content_tag(:div, :class => smart_listing_config.classes(:main), :id => name, :data => data) do
          concat(content_tag(:div, "", :class => smart_listing_config.classes(:loading)))
          concat(content_tag(:div, :class => smart_listing_config.classes(:content)) do
            concat(capture(builder, &block))
          end)
        end
      end

      output
    end

    def smart_listing_render name = controller_name, *args
      options = args.dup.extract_options!
      smart_listing_for(name, *args) do |smart_listing|
        concat(smart_listing.render_list(options[:locals]))
      end
    end

    def smart_listing_controls_for name, *args, &block
      smart_listing = @smart_listings.try(:[], name)

      classes = [smart_listing_config.classes(:controls), args.first.try(:[], :class)]

      form_tag(smart_listing.try(:href) || {}, :remote => smart_listing.try(:remote?) || true, :method => :get, :class => classes, :data => {smart_listing_config.data_attributes(:main) => name}) do
        concat(content_tag(:div, :style => "margin:0;padding:0;display:inline") do
          concat(hidden_field_tag("#{smart_listing.try(:base_param)}[_]", 1, :id => nil)) # this forces smart_listing_update to refresh the list
        end)
        concat(capture(&block))
      end
    end

    # Render item action buttons (ie. edit, destroy and custom ones)
    def smart_listing_item_actions actions = []
      content_tag(:span) do
        actions.each do |action|
          next unless action.is_a?(Hash)

          locals = {
            :action_if => action.has_key?(:if) ? action[:if] : true,
            :url => action.delete(:url),
            :icon => action.delete(:icon),
            :title => action.delete(:title),
          }

          template = nil
          action_name = action[:name].to_sym

          case action_name
          when :show
            locals[:icon] ||= smart_listing_config.classes(:icon_show)
						template = 'action_show'
          when :edit
            locals[:icon] ||= smart_listing_config.classes(:icon_edit)
						template = 'action_edit'
          when :destroy
            locals[:icon] ||= smart_listing_config.classes(:icon_trash)
            locals.merge!(
              :confirmation => action.delete(:confirmation),
            )
            template = 'action_delete'
          when :custom
            locals.merge!(
              :html_options => action,
            )
            template = 'action_custom'
          end

          locals[:icon] = [locals[:icon], smart_listing_config.classes(:muted)] if !locals[:action_if]

          if template
            concat(render(:partial => "smart_listing/#{template}", :locals => locals))
          else
            concat(render(:partial => "smart_listing/action_#{action_name}", :locals => {:action => action}))
          end
        end
      end
    end

    def smart_listing_limit_left name
      name = name.to_sym
      smart_listing = @smart_listings[name]

      smart_listing.max_count - smart_listing.count
    end

    #################################################################################################
    # JS helpers:

    # Updates smart listing
    #
    # Posible calls:
    # smart_listing_update name, options = {}
    # smart_listing_update options = {}
    def smart_listing_update *args
      options = args.extract_options!
      name = (args[0] || options[:name] || controller_name).to_sym
      smart_listing = @smart_listings[name]

      # don't update list if params are missing (prevents interfering with other lists)
      if params.keys.select{|k| k.include?("smart_listing")}.present? && !params[smart_listing.base_param]
        return unless options[:force]
      end

      builder = Builder.new(name, smart_listing, self, {}, nil)
      render(:partial => 'smart_listing/update_list', :locals => {
        :name => smart_listing.name,
        :part => smart_listing.partial,
        :smart_listing => builder,
        :smart_listing_data => {
          smart_listing_config.data_attributes(:params) => smart_listing.all_params,
          smart_listing_config.data_attributes(:max_count) => smart_listing.max_count,
          smart_listing_config.data_attributes(:item_count) => smart_listing.count,
        },
        :locals => options[:locals] || {}
      })
    end

    # Renders single item (i.e for create, update actions)
    #
    # Possible calls:
    # smart_listing_item name, item_action, object = nil, partial = nil, options = {}
    # smart_listing_item item_action, object = nil, partial = nil, options = {}
    def smart_listing_item *args
      options = args.extract_options!
      if [:create, :create_continue, :destroy, :edit, :new, :remove, :update].include?(args[1])
        name = args[0]
        item_action = args[1]
        object = args[2]
        partial = args[3]
      else
        name = (options[:name] || controller_name).to_sym
        item_action = args[0]
        object = args[1]
        partial = args[2]
      end
      type = object.class.name.downcase.to_sym if object
      id = options[:id] || object.try(:id)
      valid = options[:valid] if options.has_key?(:valid)
      object_key = options.delete(:object_key) || :object
      new = options.delete(:new)

      render(:partial => "smart_listing/item/#{item_action.to_s}", :locals => {:name => name, :id => id, :valid => valid, :object_key => object_key, :object => object, :part => partial, :new => new})
    end
  end
end

```

# app/helpers/smart_listing/application_helper.rb

```rb
require 'smart_listing/helper'
module SmartListing
  module ApplicationHelper
  end
end

```

# app/assets/javascripts/smart_listing.coffee.erb

```erb
# endsWith polyfill
if !String::endsWith
  String::endsWith = (search, this_len) ->
    if this_len == undefined or this_len > @length
      this_len = @length
    @substring(this_len - (search.length), this_len) == search

# Useful when SmartListing target url is different than current one
$.rails.href = (element) ->
  element.attr("href") || element.data("<%= SmartListing.config.data_attributes(:href) %>") || window.location.pathname

class window.SmartListing
  class Config
    @options: <%= SmartListing.config.dump_json %>

    @merge: (d) ->
      $.extend true, @options, d || $("body").data("smart-listing-config")

    @class: (name)->
      @options["constants"]["classes"][name]

    @class_name: (name) ->
      ".#{@class(name)}"

    @data_attribute: (name)->
      @options["constants"]["data_attributes"][name]

    @selector: (name)->
      @options["constants"]["selectors"][name]

    @element_template: (name)->
      @options["constants"]["element_templates"][name]

    @bootstrap_commands: (name)->
      @options["constants"]["bootstrap_commands"][name]

  @config: Config


  constructor: (e) ->
    @container = e
    @name = @container.attr("id")
    @loading = @container.find(SmartListing.config.class_name("loading"))
    @content = @container.find(SmartListing.config.class_name("content"))
    @status = $("#{SmartListing.config.class_name("status")} [data-#{SmartListing.config.data_attribute("main")}='#{@name}']")
    @confirmed = null
    @popovers = {}

    @container.on "ajax:before", "#{SmartListing.config.class_name("item_actions")}, #{SmartListing.config.class_name("pagination_container")}", (e) =>
      @fadeLoading()

    @container.on "ajax:success", (e) =>
      if $(e.target).is("#{SmartListing.config.class_name("item_actions")} #{SmartListing.config.selector("item_action_destroy")}")
        # handle HEAD OK response for deletion request
        editable = $(e.target).closest(SmartListing.config.class_name("editable"))
        if @container.find(SmartListing.config.class_name("editable")).length == 1
          @reload()
          return false
        else
          editable.remove()

          @container.trigger("smart_listing:destroy", editable)

        @changeItemCount(-1)
        @refresh()

        @fadeLoaded()
        return false

    @container.on "click", SmartListing.config.selector("edit_cancel"), (event) =>
      editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"))
      if(editable.length > 0)
        # Cancel edit
        @cancelEdit(editable)
      else
        # Cancel new record
        @container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"))
        @container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"))

      @setAutoshow(false)
      false

    @container.on "click", "#{SmartListing.config.class_name("item_actions")} a[data-#{SmartListing.config.data_attribute("confirmation")}]", (event) =>
      $.fn.smart_listing.confirm $(event.currentTarget), $(event.currentTarget).data(SmartListing.config.data_attribute("confirmation"))

    @container.on "click", "#{SmartListing.config.class_name("item_actions")} a[data-#{SmartListing.config.data_attribute("popover")}]", (event) =>
      name = $(event.currentTarget).data(SmartListing.config.data_attribute("popover"))
      if jQuery.isFunction(@popovers[name])
        @popovers[name]($(event.currentTarget))
        false


    @container.on "click", "input[type=text]#{SmartListing.config.class_name("autoselect")}", (event) ->
      $(this).select()

    @container.on "change", SmartListing.config.class_name("callback"), (event) =>
      checkbox = $(event.currentTarget)
      id = checkbox.closest(SmartListing.config.selector("row")).data(SmartListing.config.data_attribute("id"))
      data = {}
      data[checkbox.val()] = checkbox.is(":checked")
      $.ajax({
        beforeSend: (xhr, settings) ->
          xhr.setRequestHeader "accept", "*/*;q=0.5, " + settings.accepts.script
        url: @container.data(SmartListing.config.data_attribute("callback_href")),
        type: "POST",
        data: data,
      })

  fadeLoading: =>
    $.fn.smart_listing.onLoading(@content, @loading)

  fadeLoaded: =>
    $.fn.smart_listing.onLoaded(@content, @loading)
  
  itemCount: =>
    parseInt(@container.data(SmartListing.config.data_attribute("item_count")))

  maxCount: =>
    parseInt(@container.data(SmartListing.config.data_attribute("max_count")))

  setAutoshow: (v) =>

    @container.data(SmartListing.config.data_attribute("autoshow"), v)

  changeItemCount: (value) =>
    count = @container.data(SmartListing.config.data_attribute("item_count")) + value
    @container.data(SmartListing.config.data_attribute("item_count"), count)
    @container.find(SmartListing.config.selector("pagination_count")).html(count)

  cancelEdit: (editable) =>
    if editable.data(SmartListing.config.data_attribute("inline_edit_backup"))
      editable.html(editable.data(SmartListing.config.data_attribute("inline_edit_backup")))
      editable.removeClass(SmartListing.config.class("inline_editing"))
      editable.removeData(SmartListing.config.data_attribute("inline_edit_backup"))
  
  # Callback called when record is added/deleted using ajax request
  refresh: () =>
    header = @content.find(SmartListing.config.selector("head"))
    footer = @content.find(SmartListing.config.class_name("pagination_per_page"))
    no_records = @content.find(SmartListing.config.class_name("no_records"))

    if @itemCount() == 0
      header.hide()
      footer.hide()
      no_records.show()
    else
      header.show()
      footer.show()
      no_records.hide()

    if @maxCount()
      if @itemCount() >= @maxCount()
        @container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"))
        @container.find(SmartListing.config.class_name("new_item_action")).addClass(SmartListing.config.class("hidden"))
      else
        if @container.data(SmartListing.config.data_attribute("autoshow"))
          @container.find(SmartListing.config.class_name("new_item_placeholder")).removeClass(SmartListing.config.class("hidden"))
          @container.find(SmartListing.config.class_name("new_item_action")).addClass(SmartListing.config.class("hidden"))
        else
          @container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"))
          @container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"))

    @status.each (index, status) =>
      $(status).find(SmartListing.config.class_name("limit")).html(@maxCount() - @itemCount())
      if @maxCount() - @itemCount() == 0
        $(status).find(SmartListing.config.class_name("limit_alert")).show()
      else
        $(status).find(SmartListing.config.class_name("limit_alert")).hide()
  
  # Trigger AJAX request to reload the list
  reload: () =>
    $.rails.handleRemote(@container)
  
  params: (value) =>
    if value
      @container.data(SmartListing.config.data_attribute("params"), value)
    else
      @container.data(SmartListing.config.data_attribute("params"))

  registerPopover: (name, callback) =>
    @popovers[name] = callback

  editable: (id) =>
    @container.find("#{SmartListing.config.class_name("editable")}[data-#{SmartListing.config.data_attribute("id")}=#{id}]")

  #################################################################################################
  # Methods executed by rails UJS:

  new_item: (content) =>
    if !@maxCount() || (@itemCount() < @maxCount())
      new_item_action = @container.find(SmartListing.config.class_name("new_item_action"))
      new_item_placeholder = @container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"))

      @container.find(SmartListing.config.class_name("editable")).each (i, v) =>
        @cancelEdit($(v))

      new_item_action.addClass(SmartListing.config.class("hidden"))
      new_item_placeholder.removeClass(SmartListing.config.class("hidden"))
      new_item_placeholder.html(content)
      new_item_placeholder.addClass(SmartListing.config.class("inline_editing"))

      @container.trigger("smart_listing:new", new_item_placeholder)

      @fadeLoaded()

  create: (id, success, content) =>
    new_item_action = @container.find(SmartListing.config.class_name("new_item_action"))
    new_item_placeholder = @container.find(SmartListing.config.class_name("new_item_placeholder"))

    if success
      new_item_placeholder.addClass(SmartListing.config.class("hidden"))
      new_item_action.removeClass(SmartListing.config.class("hidden"))

      new_item = $(SmartListing.config.element_template("row")).addClass(SmartListing.config.class("editable"))
      new_item.attr("data-#{SmartListing.config.data_attribute("id")}", id)
      new_item.html(content)

      if new_item_placeholder.length != 0
        if new_item_placeholder.data("insert-mode") == "after"
          new_item_placeholder.after(new_item)
        else
          new_item_placeholder.before(new_item)
      else
        @content.append(new_item)

      @container.trigger("smart_listing:create:success", new_item)

      @changeItemCount(1)
      @refresh()
    else
      new_item_placeholder.html(content)

      @container.trigger("smart_listing:create:fail", new_item_placeholder)

    @fadeLoaded()

  edit: (id, content) =>
    @container.find(SmartListing.config.class_name("editable")).each (i, v) =>
      @cancelEdit($(v))
    @container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"))
    @container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"))

    editable = @editable(id)
    editable.data(SmartListing.config.data_attribute("inline_edit_backup"), editable.html())
    editable.html(content)
    editable.addClass(SmartListing.config.class("inline_editing"))

    @container.trigger("smart_listing:edit", editable)

    @fadeLoaded()

  update: (id, success, content) =>
    editable = @editable(id)
    if success
      editable.removeClass(SmartListing.config.class("inline_editing"))
      editable.removeData(SmartListing.config.data_attribute("inline_edit_backup"))
      editable.html(content)

      @container.trigger("smart_listing:update:success", editable)

      @refresh()
    else
      editable.html(content)

      @container.trigger("smart_listing:update:fail", editable)

    @fadeLoaded()
  
  destroy: (id, destroyed) =>
    # No need to do anything here, already handled by ajax:success handler

  remove: (id) =>
    editable = @editable(id)
    editable.remove()

    @container.trigger("smart_listing:remove", editable)
  
  update_list: (content, data) =>
    @container.data(SmartListing.config.data_attribute("params"), $.extend(@container.data(SmartListing.config.data_attribute("params")), data[SmartListing.config.data_attribute("params")]))
    @container.data(SmartListing.config.data_attribute("max_count"), data[SmartListing.config.data_attribute("max_count")])
    @container.data(SmartListing.config.data_attribute("item_count"), data[SmartListing.config.data_attribute("item_count")])

    @content.html(content)

    @refresh()
    @fadeLoaded()

    @container.trigger("smart_listing:update_list", @container)

$.fn.smart_listing = () ->
  map = $(this).map () ->
    if !$(this).data(SmartListing.config.data_attribute("main"))
      $(this).data(SmartListing.config.data_attribute("main"), new SmartListing($(this)))
    $(this).data(SmartListing.config.data_attribute("main"))
  if map.length == 1
    map[0]
  else
    map

$.fn.smart_listing.observeField = (field, opts = {}) ->
   key_timeout = null
   last_value = null
   options =
     onFilled: () ->
     onEmpty: () ->
     onChange: () ->
   options = $.extend(options, opts)
 
   keyChange = () ->
     if field.val().length > 0
       options.onFilled()
     else
       options.onEmpty()

     if field.val() == last_value && field.val().length != 0
       return
     lastValue = field.val()
 
     options.onChange()
 
   field.data(SmartListing.config.data_attribute("observed"), true)
 
   field.bind "keydown", (e) ->
     if(key_timeout)
       clearTimeout(key_timeout)
 
     key_timeout = setTimeout(->
       keyChange()
     , 400)

$.fn.smart_listing.showPopover = (elem, body) ->
  elem.popover(SmartListing.config.bootstrap_commands("popover_destroy"))
  elem.popover(content: body, html: true, trigger: "manual")
  elem.popover("show")

$.fn.smart_listing.showConfirmation = (confirmation_elem, msg, confirm_callback) ->
  buildPopover = (confirmation_elem, msg) ->
    deletion_popover = $("<div/>").addClass("confirmation_box")
    deletion_popover.append($("<p/>").html(msg))
    deletion_popover.append($("<p/>")
      .append($("<button/>").html("Yes").addClass("btn btn-danger ").click (event) =>
        # set @confirmed element and emulate click on icon
        editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"))
        confirm_callback(confirmation_elem)
        $(confirmation_elem).click()
        $(confirmation_elem).popover(SmartListing.config.bootstrap_commands("popover_destroy"))
      )
      .append(" ")
      .append($("<button/>").html("No").addClass("btn btn-small").click (event) =>
        editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"))
        $(confirmation_elem).popover(SmartListing.config.bootstrap_commands("popover_destroy"))
      )
    )

  $.fn.smart_listing.showPopover confirmation_elem, buildPopover(confirmation_elem, msg)

$.fn.smart_listing.confirm = (elem, msg) ->
  if !elem.data("confirmed")
    # We need confirmation
    $.fn.smart_listing.showConfirmation elem, msg, (confirm_elem) =>
      confirm_elem.data("confirmed", true)
    false
  else
    # Confirmed, reset flag and go ahead with deletion
    elem.data("confirmed", false)
    true

$.fn.smart_listing.onLoading = (content, loader) ->
  content.stop(true).fadeTo(500, 0.2)
  loader.show()
  loader.stop(true).fadeTo(500, 1)

$.fn.smart_listing.onLoaded = (content, loader) ->
  content.stop(true).fadeTo(500, 1)
  loader.stop(true).fadeTo 500, 0, () =>
    loader.hide()

$.fn.smart_listing_controls = () ->
  reload = (controls) ->
    container = $("##{controls.data(SmartListing.config.data_attribute("main"))}")
    smart_listing = container.smart_listing()

    # serialize form and merge it with smart listing params
    prms = {}
    $.each controls.serializeArray(), (i, field) ->
      if field.name.endsWith("[]")
        field_name = field.name.slice(0, field.name.length - 2)
        if Array.isArray(prms[field_name])
          prms[field_name].push field.value
        else
          prms[field_name] = [field.value]
      else
        prms[field.name] = field.value

    prms = $.extend(smart_listing.params(), prms)
    smart_listing.params(prms)

    smart_listing.fadeLoading()
    smart_listing.reload()

  $(this).each () ->
    # avoid double initialization
    return if $(this).data(SmartListing.config.data_attribute("controls_initialized"))
    $(this).data(SmartListing.config.data_attribute("controls_initialized"), true)

    controls = $(this)
    smart_listing = $("##{controls.data(SmartListing.config.data_attribute("main"))}")
    reset = controls.find(SmartListing.config.class_name("controls_reset"))

    controls.submit ->
      # setup smart listing params, reload and don"t actually submit controls form
      reload(controls)
      false

    controls.find("input, select").change () ->
      unless $(this).data(SmartListing.config.data_attribute("observed")) # do not submit controls form when changed field is observed (observing submits form by itself)
        reload(controls)

    $.fn.smart_listing_controls.filter(controls.find(SmartListing.config.class_name("filtering")))

$.fn.smart_listing_controls.filter = (filter) ->
  form = filter.closest("form")
  button = form.find(SmartListing.config.selector("filtering_button"))
  icon = form.find(SmartListing.config.selector("filtering_icon"))
  field = form.find(SmartListing.config.selector("filtering_input"))

  $.fn.smart_listing.observeField(field,
    onFilled: ->
      icon.removeClass(SmartListing.config.class("filtering_search"))
      icon.addClass(SmartListing.config.class("filtering_cancel"))
      button.removeClass(SmartListing.config.class("filtering_disabled"))
    onEmpty: ->
      icon.addClass(SmartListing.config.class("filtering_search"))
      icon.removeClass(SmartListing.config.class("filtering_cancel"))
      button.addClass(SmartListing.config.class("filtering_disabled"))
    onChange: ->
      form.submit()
  )

  button.click ->
    if field.val().length > 0
      field.val("")
      field.trigger("keydown")
    return false

ready = ->
  $(SmartListing.config.class_name("main")).smart_listing()
  $(SmartListing.config.class_name("controls")).smart_listing_controls()

$(document).ready ready
$(document).on "page:load turbolinks:load", ready

```

# spec/dummy/lib/assets/.keep

```

```

# spec/dummy/db/migrate/20180126065408_create_user.rb

```rb
class CreateUser < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.boolean :boolean
    end
  end
end

```

# spec/dummy/config/locales/en.yml

```yml
# Files in the config/locales directory are used for internationalization
# and are automatically loaded by Rails. If you want to use locales other
# than English, add the necessary files in this directory.
#
# To use the locales, use `I18n.t`:
#
#     I18n.t 'hello'
#
# In views, this is aliased to just `t`:
#
#     <%= t('hello') %>
#
# To use a different locale, set it with `I18n.locale`:
#
#     I18n.locale = :es
#
# This would use the information in config/locales/es.yml.
#
# To learn more, please read the Rails Internationalization guide
# available at http://guides.rubyonrails.org/i18n.html.

en:
  hello: "Hello world"

```

# spec/dummy/config/initializers/wrap_parameters.rb

```rb
# Be sure to restart your server when you modify this file.

# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json] if respond_to?(:wrap_parameters)
end

# To enable root element in JSON for ActiveRecord objects.
# ActiveSupport.on_load(:active_record) do
#  self.include_root_in_json = true
# end

```

# spec/dummy/config/initializers/smart_listing.rb

```rb
SmartListing.configure do |config|
  config.global_options({
    #:param_names  => {                                              # param names
      #:page                         => :page,
      #:per_page                     => :per_page,
      #:sort                         => :sort,
    #},
    #:array                          => false,                       # controls whether smart list should be using arrays or AR collections
    #:max_count                      => nil,                         # limit number of rows
    #:unlimited_per_page             => false,                       # allow infinite page size
    #:paginate                       => true,                        # allow pagination
    #:memorize_per_page              => false,                       # save per page settings in the cookie
    :page_sizes                     => [3, 10],          # set available page sizes array
    #:kaminari_options               => {:theme => "smart_listing"}, # Kaminari's paginate helper options
    #:sort_dirs                      => [nil, "asc", "desc"],        # Default sorting directions cycle of sortables
  })

  config.constants :classes, {
    #:main                  => "smart-listing",
    #:editable              => "editable",
    #:content               => "content",
    #:loading               => "loading",
    #:status                => "smart-listing-status",
    #:item_actions          => "actions",
    #:new_item_placeholder  => "new-item-placeholder",
    #:new_item_action       => "new-item-action",
    #:new_item_button       => "btn",
    #:hidden                => "hidden",
    #:autoselect            => "autoselect",
    #:callback              => "callback",
    #:pagination_per_page   => "pagination-per-page text-center",
    #:inline_editing        => "info",
    #:no_records            => "no-records",
    #:limit                 => "smart-listing-limit",
    #:limit_alert           => "smart-listing-limit-alert",
    #:controls              => "smart-listing-controls",
    #:controls_reset        => "reset",
    #:filtering             => "filter",
    #:filtering_search      => "glyphicon-search",
    #:filtering_cancel      => "glyphicon-remove",
    #:filtering_disabled    => "disabled",
    #:sortable              => "sortable",
    #:icon_new              => "glyphicon glyphicon-plus",
    #:icon_edit             => "glyphicon glyphicon-pencil",
    #:icon_trash            => "glyphicon glyphicon-trash",
    #:icon_inactive         => "glyphicon glyphicon-circle",
    #:icon_show             => "glyphicon glyphicon-share-alt",
    #:icon_sort_none        => "glyphicon glyphicon-resize-vertical",
    #:icon_sort_up          => "glyphicon glyphicon-chevron-up",
    #:icon_sort_down        => "glyphicon glyphicon-chevron-down",
    #:muted                 => "text-muted",
  }

  config.constants :data_attributes, {
    #:main                  => "smart-listing",
    #:controls_initialized  => "smart-listing-controls-initialized",
    #:confirmation          => "confirmation",
    #:id                    => "id",
    #:href                  => "href",
    #:callback_href         => "callback-href",
    #:max_count             => "max-count",
    #:item_count            => "item-count",
    #:inline_edit_backup    => "smart-listing-edit-backup",
    #:params                => "params",
    #:observed              => "observed",
    #:href                  => "href",
    #:autoshow              => "autoshow",
    #:popover               => "slpopover",
  }

  config.constants :selectors, {
    #:item_action_destroy   => "a.destroy",
    #:edit_cancel           => "button.cancel",
    #:row                   => "tr",
    #:head                  => "thead",
    #:filtering_icon        => "i"
    #:filtering_button      => "button",
    #:filtering_icon        => "button span",
    #:filtering_input       => ".filter input",
    #:pagination_count      => ".pagination-per-page .count",
  }
end

```

# spec/dummy/config/initializers/session_store.rb

```rb
# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_dummy_session'

```

# spec/dummy/config/initializers/mime_types.rb

```rb
# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

```

# spec/dummy/config/initializers/inflections.rb

```rb
# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end

```

# spec/dummy/config/initializers/filter_parameter_logging.rb

```rb
# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

```

# spec/dummy/config/initializers/cookies_serializer.rb

```rb
# Be sure to restart your server when you modify this file.

Rails.application.config.action_dispatch.cookies_serializer = :json
```

# spec/dummy/config/initializers/backtrace_silencers.rb

```rb
# Be sure to restart your server when you modify this file.

# You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
# Rails.backtrace_cleaner.add_silencer { |line| line =~ /my_noisy_library/ }

# You can also remove all the silencers if you're trying to debug a problem that might stem from framework code.
# Rails.backtrace_cleaner.remove_silencers!

```

# spec/dummy/config/initializers/assets.rb

```rb
# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

```

# spec/dummy/config/environments/test.rb

```rb
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_assets  = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end

```

# spec/dummy/config/environments/production.rb

```rb
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_assets = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end

```

# spec/dummy/config/environments/development.rb

```rb
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end

```

# spec/dummy/app/models/user.rb

```rb
class User < ActiveRecord::Base
  scope :by_boolean, -> { where(:boolean => true) }
  scope :like, -> (filter) { where("UPPER(name) LIKE UPPER(?) OR UPPER(email) LIKE UPPER(?)", "%#{filter}%", "%#{filter}%")}

  def self.search(word)
    where('name LIKE :word OR email LIKE :word', word: "%#{word}%")
  end
end

```

# spec/dummy/app/models/application_record.rb

```rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

```

# spec/dummy/app/models/.keep

```

```

# spec/dummy/app/mailers/.keep

```

```

# spec/dummy/app/helpers/application_helper.rb

```rb
module ApplicationHelper
end

```

# spec/dummy/app/controllers/users_controller.rb

```rb
class UsersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  def index
    smart_listing_create partial: 'users/list'
  end

  def sortable
    smart_listing_create partial: 'users/sortable_list',
      default_sort: { name: 'desc' }
    render 'index'
  end

  def searchable
    users = User.all
    users = users.search(params[:filter]) if params[:filter]
    @users = smart_listing_create collection: users, partial: 'users/searchable_list',
      default_sort: { name: 'desc' }
  end

  private

  def smart_listing_resource
    @user ||= params[:id] ? User.find(params[:id]) : User.new(params[:user])
  end
  helper_method :smart_listing_resource

  def smart_listing_collection
    @users ||= User.all
  end
  helper_method :smart_listing_collection
end

```

# spec/dummy/app/controllers/application_controller.rb

```rb
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end

```

# lib/generators/smart_listing/templates/initializer.rb

```rb
SmartListing.configure do |config|
  config.global_options({
    #:param_names  => {                                              # param names
      #:page                         => :page,
      #:per_page                     => :per_page,
      #:sort                         => :sort,
    #},
    #:array                          => false,                       # controls whether smart list should be using arrays or AR collections
    #:max_count                      => nil,                         # limit number of rows
    #:unlimited_per_page             => false,                       # allow infinite page size
    #:paginate                       => true,                        # allow pagination
    #:memorize_per_page              => false,                       # save per page settings in the cookie
    #:page_sizes                     => DEFAULT_PAGE_SIZES,          # set available page sizes array
    #:kaminari_options               => {:theme => "smart_listing"}, # Kaminari's paginate helper options
    #:sort_dirs                      => [nil, "asc", "desc"],        # Default sorting directions cycle of sortables
  })

  config.constants :classes, {
    #:main                  => "smart-listing",
    #:editable              => "editable",
    #:content               => "content",
    #:loading               => "loading",
    #:status                => "smart-listing-status",
    #:item_actions          => "actions",
    #:new_item_placeholder  => "new-item-placeholder",
    #:new_item_action       => "new-item-action",
    #:new_item_button       => "btn",
    #:hidden                => "hidden",
    #:autoselect            => "autoselect",
    #:callback              => "callback",
    #:pagination_wrapper    => "text-center",
    #:pagination_container  => "pagination",
    #:pagination_per_page   => "pagination-per-page text-center",
    #:inline_editing        => "info",
    #:no_records            => "no-records",
    #:limit                 => "smart-listing-limit",
    #:limit_alert           => "smart-listing-limit-alert",
    #:controls              => "smart-listing-controls",
    #:controls_reset        => "reset",
    #:filtering             => "filter",
    #:filtering_search      => "glyphicon-search",
    #:filtering_cancel      => "glyphicon-remove",
    #:filtering_disabled    => "disabled",
    #:sortable              => "sortable",
    #:icon_new              => "glyphicon glyphicon-plus",
    #:icon_edit             => "glyphicon glyphicon-pencil",
    #:icon_trash            => "glyphicon glyphicon-trash",
    #:icon_inactive         => "glyphicon glyphicon-circle",
    #:icon_show             => "glyphicon glyphicon-share-alt",
    #:icon_sort_none        => "glyphicon glyphicon-resize-vertical",
    #:icon_sort_up          => "glyphicon glyphicon-chevron-up",
    #:icon_sort_down        => "glyphicon glyphicon-chevron-down",
    #:muted                 => "text-muted",
  }

  config.constants :data_attributes, {
    #:main                  => "smart-listing",
    #:controls_initialized  => "smart-listing-controls-initialized",
    #:confirmation          => "confirmation",
    #:id                    => "id",
    #:href                  => "href",
    #:callback_href         => "callback-href",
    #:max_count             => "max-count",
    #:item_count            => "item-count",
    #:inline_edit_backup    => "smart-listing-edit-backup",
    #:params                => "params",
    #:observed              => "observed",
    #:autoshow              => "autoshow",
    #:popover               => "slpopover",
  }

  config.constants :selectors, {
    #:item_action_destroy   => "a.destroy",
    #:edit_cancel           => "button.cancel",
    #:row                   => "tr",
    #:head                  => "thead",
    #:filtering_icon        => "i"
    #:filtering_button      => "button",
    #:filtering_icon        => "button span",
    #:filtering_input       => ".filter input",
    #:pagination_count      => ".pagination-per-page .count",
  }

  config.constants :element_templates, {
    #:row => "<tr />",
  }

  config.constants :bootstrap_commands, {
    #:popover_destroy       => "destroy", # Bootstrap 4 requries dipsose instead of destroy
  }
end

```

# app/views/smart_listing/item/_update.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.update(<%= id.to_json.html_safe %>, <%= valid.nil? ? object.valid? : valid %>, "<%= escape_javascript(render(:partial => part, :locals => {object_key => object})) %>");

```

# app/views/smart_listing/item/_remove.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.remove(<%= id.to_json.html_safe %>);

```

# app/views/smart_listing/item/_new.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.new_item("<%= escape_javascript(render(:partial => part, :locals => {object_key => object})) %>");

```

# app/views/smart_listing/item/_edit.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.edit(<%= id.to_json.html_safe %>, "<%= escape_javascript(render(:partial => part, :locals => {object_key => object})) %>");

```

# app/views/smart_listing/item/_destroy.js.erb

```erb
var smart_listing = $('#<%= name.to_s %>').smart_listing();
smart_listing.destroy(<%= id.to_json.html_safe %>, <%= object.destroyed? %>);

```

# app/views/smart_listing/item/_create_continue.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.setAutoshow(true);
smart_listing.create(<%= (id || 0).to_json.html_safe %>, <%= object.persisted? %>, "<%= escape_javascript(render(:partial => part, :locals => {object_key => object})) %>");
<% if object.persisted? %>
  smart_listing.new_item("<%= escape_javascript(render(:partial => new.last, :locals => {object_key => new.first})) %>");
<% end %>

```

# app/views/smart_listing/item/_create.js.erb

```erb
var smart_listing = $('#<%= name %>').smart_listing();
smart_listing.setAutoshow(false);
smart_listing.create(<%= (id || 0).to_json.html_safe %>, <%= object.persisted? %>, "<%= escape_javascript(render(:partial => part, :locals => {object_key => object})) %>");

```

# app/views/kaminari/smart_listing/_prev_page.html.erb

```erb
<%# Link to the "Previous" page
  - available local variables
    url:           url to the previous page
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<% unless current_page.first? %>
<li class="prev">
  <%= link_to_unless current_page.first?, raw(t 'views.pagination.previous'), url, :rel => 'prev', :remote => remote %>
</li>
<% end %>

```

# app/views/kaminari/smart_listing/_paginator.html.erb

```erb
<%# The container tag
  - available local variables
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
    paginator:     the paginator that renders the pagination tags inside
-%>
<%= paginator.render do -%>
  <div class="<%= smart_listing_config.classes(:pagination_wrapper) %>">
    <ul class="<%= smart_listing_config.classes(:pagination_container) %>">
      <%= first_page_tag unless current_page.first? %>
      <%= prev_page_tag unless current_page.first? %>
      <% each_page do |page| -%>
          <% if page.left_outer? || page.right_outer? || page.inside_window? -%>
            <%= page_tag page %>
        <% elsif !page.was_truncated? -%>
            <%= gap_tag %>
        <% end -%>
      <% end -%>
      <%= next_page_tag unless current_page.last? %>
      <%= last_page_tag unless current_page.last? %>
    </ul>
  </div>
<% end -%>

```

# app/views/kaminari/smart_listing/_page.html.erb

```erb
<%# Link showing page number
  - available local variables
    page:          a page object for "this" page
    url:           url to this page
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<li class="page<%= ' active' if page.current? %>">
  <%= link_to page, url, opts = {:remote => remote, :rel => page.next? ? 'next' : page.prev? ? 'prev' : nil} %>
</li>

```

# app/views/kaminari/smart_listing/_next_page.html.erb

```erb
<%# Link to the "Next" page
  - available local variables
    url:           url to the next page
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<% unless current_page.last? %>
  <li class="next_page">
  <%= link_to_unless current_page.last?, raw(t 'views.pagination.next'), url, :rel => 'next', :remote => remote %>
  </li>
<% end %>

```

# app/views/kaminari/smart_listing/_last_page.html.erb

```erb
<%# Link to the "Last" page
  - available local variables
    url:           url to the last page
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<% unless current_page.last? %>
  <li class="last next"><%# "next" class present for border styling in twitter bootstrap %>
  <%= link_to_unless current_page.last?, raw(t 'views.pagination.last'), url, {:remote => remote} %>
  </li>
<% end %>

```

# app/views/kaminari/smart_listing/_gap.html.erb

```erb
<%# Non-link tag that stands for skipped pages...
  - available local variables
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<li class="page gap disabled"><a href="#" onclick="return false;"><%= raw(t 'views.pagination.truncate') %></a></li>

```

# app/views/kaminari/smart_listing/_first_page.html.erb

```erb
<%# Link to the "First" page
  - available local variables
    url:           url to the first page
    current_page:  a page object for the currently displayed page
    total_pages:   total number of pages
    per_page:      number of items to fetch per page
    remote:        data-remote
-%>
<% unless current_page.first? %>
  <li class="first">
  <%= link_to_unless current_page.first?, raw(t 'views.pagination.first'), url, :remote => remote %>
  </li>
<% end %>

```

# spec/dummy/app/views/users/searchable.js.erb

```erb
<%= smart_listing_update %>



```

# spec/dummy/app/views/users/searchable.html.erb

```erb
<%= smart_listing_controls_for(:users, {class: 'form-inline text-right'}) do %>
  <div class="form-group filter input-append">
    <%= text_field_tag :filter, '',
      class: 'search form-control', placeholder: 'Search...',
      autocomplete: :off %>
  </div>
  <button class='btn btn-primary disabled' type='submit'>
    <span class='glyphicon glyphicon-search'></span>
  </button>
<% end %>
<%= smart_listing_render %>


```

# spec/dummy/app/views/users/index.js.erb

```erb
<%= smart_listing_update %>

```

# spec/dummy/app/views/users/index.html.erb

```erb
<%= smart_listing_render %>

```

# spec/dummy/app/views/users/_sortable_list.html.erb

```erb
<% unless smart_listing.empty? %>
  <table class="table table-striped">
    <thead>
      <th class="col-md-6 name">
        <%= smart_listing.sortable "Name", "name" %>
      </th>
      <th class="col-md-6 email">
        <%= smart_listing.sortable "Email", "email" %>
      </th>
    </thead>
    <tbody>
      <% smart_listing.collection.each do |user| %>
        <tr>
          <td><%= user.name %></td>
          <td><%= user.email %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
  <%= smart_listing.paginate %>
  <%= smart_listing.pagination_per_page_links %>
<% else %>
  <p class="warning">No records!</p>
<% end %>

```

# spec/dummy/app/views/users/_searchable_list.html.erb

```erb
<% unless smart_listing.empty? %>
  <table class="table table-striped">
    <thead>
      <th class="col-md-6">Name</th>
      <th class="col-md-6">Email</th>
    </thead>
    <tbody>
      <% smart_listing.collection.each do |user| %>
        <tr>
          <td><%= user.name %></td>
          <td><%= user.email %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
  <% # Render nice pagination links fitted for Bootstrap 3 by default %>
  <%= smart_listing.paginate %>
  <%= smart_listing.pagination_per_page_links %>
<% else %>
  <p class="warning">No records!</p>
<% end %>

```

# spec/dummy/app/views/users/_list.html.erb

```erb
<% unless smart_listing.empty? %>
  <table class="table table-striped">
    <thead>
      <th class="col-md-6">Name</th>
      <th class="col-md-6">Email</th>
    </thead>
    <tbody>
      <% smart_listing.collection.each do |user| %>
        <tr>
          <td><%= user.name %></td>
          <td><%= user.email %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
  <% # Render nice pagination links fitted for Bootstrap 3 by default %>
  <%= smart_listing.paginate %>
  <%= smart_listing.pagination_per_page_links %>
<% else %>
  <p class="warning">No records!</p>
<% end %>

```

# spec/dummy/app/views/layouts/application.html.erb

```erb
<!DOCTYPE html>
<html>
<head>
  <title>Dummy</title>
  <%= stylesheet_link_tag    'application', media: 'all' %>
  <%= javascript_include_tag 'application' %>
  <%= csrf_meta_tags %>
</head>
<body>

<%= yield %>

</body>
</html>

```

# spec/dummy/app/models/concerns/.keep

```

```

# spec/dummy/app/controllers/concerns/.keep

```

```

# spec/dummy/app/controllers/admin/users_controller.rb

```rb
class Admin::UsersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  before_action :find_user, except: [:index, :new, :create]

  def index
    @users = User.all
    @users = @users.like(params[:filter]) if params[:filter]
    @users = @users.by_boolean if params[:boolean] == "1"
    smart_listing_create(:users, @users, partial: "admin/users/list")

    respond_to do |format|
      format.html
      format.js { render formats: :js }
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
  end

  def edit
  end

  def update
    @user.update_attributes(user_params)
  end

  def destroy
    @user.destroy
  end

  def change_name
    @user.update_attribute('name', 'Changed Name')
    render 'update'
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def smart_listing_resource
    @user ||= params[:id] ? User.find(params[:id]) : User.new(params[:user])
  end
  helper_method :smart_listing_resource

  def smart_listing_collection
    @users ||= User.all
  end
  helper_method :smart_listing_collection

  def user_params
    params.require(:user).permit(:name, :email)
  end
end

```

# spec/dummy/app/assets/stylesheets/application.css.scss

```scss
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or vendor/assets/stylesheets of plugins, if any, can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the bottom of the
 * compiled file so the styles you add here take precedence over styles defined in any styles
 * defined in the other CSS/SCSS files in this directory. It is generally better to create a new
 * file per style scope.
 *
 *= require_tree .
 *= require_self
 */
@import "bootstrap-sprockets";
@import "bootstrap";

// This is needed to fix overlapping icons of items on the capybara-webkit.
// https://github.com/thoughtbot/capybara-webkit/issues/494
td.actions {
  i, a, span {
    min-width: 20px;
  }
}

```

# spec/dummy/app/assets/javascripts/application.js

```js
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require smart_listing
//= require_tree .

```

# spec/dummy/app/assets/images/.keep

```

```

# spec/dummy/app/views/admin/users/index.html.erb

```erb
<%= smart_listing_controls_for(:users, {:class => "form-inline text-right"}) do %>
  <div class="checkbox">
    <label class="checkbox inline" for="boolean">
      <%= hidden_field_tag :boolean, "0", :id => "boolean" %>
      <%= check_box_tag :boolean %>
      <%= "Boolean?" %>
    </label>
  </div>
  &nbsp;
  <div class="form-group filter input-append">
    <%= text_field_tag :filter, '', :class => "search form-control", :placeholder => "Search...", :autocomplete => :off %>
  </div>
  <button class="btn btn-primary disabled" type="submit">
    <span class="glyphicon glyphicon-search"></span>
  </button>
<% end %>

<%= smart_listing_render %>

```

# spec/dummy/app/views/admin/users/_list.html.erb

```erb
<table class="table table-striped">
  <thead>
    <th class="col-md-4 name"><%= smart_listing.sortable "Name", "name"%></th> 
    <th class="col-md-4 email"><%= smart_listing.sortable "Email", "email"%></th>
    <th class="col-md-2">Boolean</th>
    <th class="col-md-2"></th>
  </thead>
  <tbody>
    <% smart_listing.collection.each do |user| %>
      <tr class="editable" data-id="<%= user.id %>">
        <%= smart_listing.render object: user, partial: "admin/users/item",
          locals: { object: user } %>
      </tr>
    <% end %>
    <%= smart_listing.item_new colspan: 4, link: new_admin_user_path %>
  </tbody>
</table>
<% # Render nice pagination links fitted for Bootstrap 3 by default %>
<%= smart_listing.paginate %>
<%= smart_listing.pagination_per_page_links %>

```

# spec/dummy/app/views/admin/users/_item.html.erb

```erb
<td>
  <%= object.name %>
</td>
<td>
  <%= object.email %>
</td>
<td>
  <% if object.boolean? %>
    <i class="glyphicon glyphicon-ok"></i>
  <% else %>
    <i class="glyphicon glyphicon-remove"></i>
  <% end %>
</td>
<td class="actions">
  <%= smart_listing_item_actions [
    {name: :edit, url: edit_admin_user_path(object)},
    {name: :destroy, url: admin_user_path(object), confirmation: 'Sure?'},
    {name: :custom, url: change_name_admin_user_path(object),
     icon: "glyphicon glyphicon-user",
     method: :put, remote: true,
     title: 'Change Name', class: 'change_name'}] %>
</td>

```

# spec/dummy/app/views/admin/users/_form.html.erb

```erb
<td colspan="2">
  <%= form_for object, url: object.new_record? ? admin_users_path : admin_user_path(object),
    remote: true, html: {class: "form-horizontal"} do |f| %>
    <div class="form-group">
      <label class="control-label col-md-3" for="user_name">Name</label>
      <div class="col-md-5">
        <%= f.text_field :name, class: 'form-control' %>
      </div>
    </div>
    <div class="form-group">
      <label class="control-label col-md-3" for="user_email">Email</label>
      <div class="col-md-5">
        <%= f.text_field :email, class: 'form-control' %>
      </div>
    </div>
    <%= f.submit "Save", class: "btn btn-primary" %>
  <% end %>
</td>

```

