# SmartListing Rails 7 Compatibility Todo List

## Completed Tasks
1. Replace CoffeeScript with JavaScript:
   - [x] Convert `app/assets/javascripts/smart_listing.coffee.erb` to JavaScript (`smart_listing.js.erb`).
   - [x] Update CoffeeScript syntax to modern JavaScript.

2. Update jQuery usage:
   - [x] Refactor jQuery code to use vanilla JavaScript.
   - [x] Remove jQuery dependencies from `smart_listing.js.erb`.

3. Update asset pipeline:
   - [x] Create `app/javascript/smart_listing/index.js` for Import Maps compatibility.

4. Update Gemfile:
   - [x] Remove `coffee-rails` dependency.
   - [x] Update gem dependencies in `smart_listing.gemspec` for Rails 7 compatibility.

5. Update README:
   - [x] Update installation and usage instructions for Rails 7.

6. Update CHANGELOG:
   - [x] Document changes made for Rails 7 compatibility.

7. Update configuration files:
   - [x] Review and update `lib/smart_listing.rb` for Rails 7 compatibility.

8. Update view helpers:
   - [x] Review and update `app/helpers/smart_listing/helper.rb` for Rails 7 compatibility.

9. Turbo compatibility:
   - [x] Ensure the gem works with Turbo, which replaces Turbolinks in Rails 7.

## Remaining Tasks
1. Update asset pipeline:
   - [ ] Update `app/assets/config/manifest.js` to use the new asset pipeline structure (if it exists).
   - [ ] Adjust how assets are included in the application layout (if applicable).

2. Update controller concerns:
   - [ ] Review and update `app/controllers/concerns/` if needed for Rails 7 compatibility.

3. Update test suite:
   - [ ] Update RSpec configuration for Rails 7.
   - [ ] Update any deprecated test syntax or helpers.
   - [ ] Add tests for new JavaScript functionality.

4. ActionView::Component:
   - [ ] Consider refactoring complex view logic into components, which are better supported in Rails 7.

5. Strong Parameters:
   - [ ] Ensure all controller actions are using Strong Parameters correctly, as Rails 7 is stricter about this.

6. Database migrations:
   - [ ] Update any old-style migrations to the new format if they exist.

7. Zeitwerk compatibility:
   - [ ] Ensure the gem's autoloading is compatible with Zeitwerk, the default autoloader in Rails 7.

8. Update CI/CD pipeline:
   - [ ] Update any continuous integration scripts to use Ruby and Rails 7 compatible versions.

9. Final Testing:
   - [ ] Perform thorough testing of all functionality in a Rails 7 environment.
   - [ ] Create a sample Rails 7 application to demonstrate and test the gem's functionality.

10. Documentation:
    - [ ] Review and update all documentation to ensure it reflects the changes made for Rails 7 compatibility.

11. Version Update:
    - [ ] Update the gem's version number to reflect the major changes made.

12. Release:
    - [ ] Prepare and publish a new release of the gem with Rails 7 compatibility.