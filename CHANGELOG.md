# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2023-05-24

### Added
- Full compatibility with Turbo in Rails 7
- Support for Rails 7
- Compatibility with Turbo (replacing Turbolinks)
- Custom events for SmartListing actions (create, new-item, destroy, edit, remove, update)
- New JavaScript module for import in Rails 7 applications

### Changed
- Removed jQuery dependency, now using vanilla JavaScript
- Updated JavaScript files to work with Turbo events instead of Turbolinks
- Modified view files and helper methods to work with the new JavaScript implementation
- Updated README with new installation and usage instructions for vanilla JavaScript and Turbo compatibility
- Converted `app/assets/javascripts/smart_listing.coffee.erb` to JavaScript (`smart_listing.js.erb`)
- Updated CoffeeScript syntax to modern JavaScript in the converted file
- Refactored JavaScript code to use modern ES6+ features
- Updated `smart_listing.gemspec` to reflect new Rails 7 compatibility
- Removed jQuery dependency, now using vanilla JavaScript
- Updated installation and usage instructions in README.md for Rails 7 and Turbo compatibility
- Refactored Kaminari view templates to use data attributes instead of jQuery-specific options
- Updated SmartListing item view templates to use custom events instead of jQuery methods
- Modified app/javascript/smart_listing/index.js to handle new custom events and Turbo compatibility

### Removed
- Deleted `app/assets/javascripts/smart_listing.coffee.erb`
- Removed jQuery and coffee-rails dependencies
- Removed Turbolinks-specific code

### Fixed
- Various bugs related to jQuery usage

## [1.2.3]

- Fix sorting to mitigate possible SQL-injection and improve tests [Ivan Korunkov]

## 1.2.2

- Remove duplicated href key from config template #146 [nfilzi]
- Replace deprecated .any? with .present? #143 [AakLak]
- Development environment update #140 [mizinsky]
- Fix sanitize_params method #137 [mizinsky]
- Enable to configure global remote option and it to affects sortable helper #131 [kitabatake]
- Kaminari update [mizinsky]
- Update Readme for Rails >= 5.1 Users [mizinsky]

## 1.2.1

- Allow to render outside of controllers [bval]
- Documentation fixes [blackcofla]
- Use id.to_json so integers and uuids will both work [sevgibson]
- Fix popover in bootstrap 4 [sevgibson]
- Fix Kaminari #num_pages deprecation warning [tylerhunt]
- Add support for Turbolinks 5 [wynksaiddestroy]
- Use #empty? for AC::Params [phoffer]
- Fix indentation in some files [boy-papan]

## 1.2.0

- Rails 5 support and Kaminari update [akostadinov]
- Better handling of nested controls params
- Fix controls not fading out list. Related to #51
- Config now includes element templates
- Add ability to pass locals to list view [GeorgeDewar]

## 1.1.2

- Some bugfixing: #20, #46, #58

## 1.1.0

- Config profiles
- Remove duplicate href key [wynksaiddestroy]
- API refactoring [GCorbel]
- Feature Specs [GCorbel]
- Avoid smart listing controls double initialization [lacco]
- Turbolinks support [wynksaiddestroy]
- Better form controls handling
- Possibility to specify sort directions

## 1.0.0

- JS Events triggered on item actions
- Fix filter resetting
- Fix new item autoshow
- Possibility to pass custom title to default actions
- Confirmation tweaks
- Multiple smart listings isolation
- New sorting architecture (and implicit sorting attributes)
- Controls helper
- Slightly changed item action templates

## 0.9.8

- Custom popovers support

## 0.9.7

- Some bugfixing
- Fix listing sorting XSS bug
- Add possibility to display new item form by default
- "Save & continue" support

## 0.9.6

- Some bugfixing
- Initial setup generator

## 0.9.5

- Fix collection counting bug
- Add builtin show action
- Make CSS class and data attribute names generic and customizable (SmartListing.configure)
- Make JavaScript more customizable

## 0.9.4

- Possibility to callback action
- Changes in templates

## 0.9.3

- Possibility to specify kaminari options
- Possibility to generate views and customize them in the app
- Better custom action handling

## 0.9.2

- Add possibility to specify available page sizes in options hash

## 0.9.0

- Initial release


[1.3.0]: https://github.com/yourusername/smart_listing/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/yourusername/smart_listing/releases/tag/v1.2.3