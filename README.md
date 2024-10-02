# SmartListing

SmartListing helps create AJAX-enabled lists of ActiveRecord collections or arrays with pagination, filtering, sorting and in-place editing.

## What's New

- **Vanilla JavaScript**: SmartListing now uses vanilla JavaScript instead of jQuery, reducing dependencies and improving performance.
- **Turbo Compatibility**: Full compatibility with Turbo in Rails 7 for smooth, modern web interactions.

## Installation

Add to your Gemfile:

```ruby
gem "smart_listing"
```

Then run:

```sh
$ bundle install
```

### Rails 7 Setup

For Rails 7, you need to import the SmartListing JavaScript module in your application's JavaScript entry point.

If you're using importmaps (default in Rails 7), add the following to your `config/importmap.rb`:

```ruby
pin "smart_listing", to: "smart_listing/index.js"
```

Then, in your `app/javascript/application.js`:

```javascript
import "smart_listing"
```

If you're using esbuild, you can import it directly in your `app/javascript/application.js`:

```javascript
import SmartListing from "smart_listing"
```

### Initializer

Optionally, you can install a configuration initializer:

```sh
$ rails generate smart_listing:install
```

It will be placed in `config/initializers/smart_listing.rb` and will allow you to tweak configuration settings like HTML classes and data attributes names.

### Custom views

SmartListing comes with built-in views. You can customize them by installing:

```sh
$ rails generate smart_listing:views
```

Files will be placed in `app/views/smart_listing`.

## Usage

In your controller, include the SmartListing helper methods:

```ruby
include SmartListing::Helper::ControllerExtensions
helper  SmartListing::Helper
```

Then, in your controller action:

```ruby
@users = smart_listing_create(:users, User.active, partial: "users/listing")
```

This creates a SmartListing named `:users` consisting of ActiveRecord scope `User.active` elements and rendered by partial `users/listing`.

In your view (e.g., `index.html.erb`), render the listing:

```erb
<%= smart_listing_render(:users) %>
```

Create a partial for the listing (e.g., `_listing.html.erb`):

```erb
<% unless smart_listing.empty? %>
  <table>
    <thead>
      <tr>
        <th><%= smart_listing.sortable "User name", "name" %></th>
        <th><%= smart_listing.sortable "Email", "email" %></th>
      </tr>
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
<% else %>
  <p class="warning">No records!</p>
<% end %>
```

For AJAX functionality with Turbo, create a Turbo Stream template (e.g., `index.turbo_stream.erb`):

```erb
<%= turbo_stream.replace "users_smart_listing" do %>
  <%= smart_listing_render :users %>
<% end %>
```

### Sorting, Filtering, and In-place Editing

For more advanced features like sorting, filtering, and in-place editing, refer to the detailed documentation in the sections below.

## Vanilla JavaScript and Turbo Compatibility

SmartListing now uses vanilla JavaScript instead of jQuery, making it lighter and more performant. It's fully compatible with Turbo in Rails 7. The JavaScript has been updated to work with Turbo events instead of Turbolinks events. 

Key points:
- No jQuery dependency
- Uses modern JavaScript features
- Works seamlessly with Turbo
- Improved performance

Make sure your Turbo Stream responses update the correct elements for smooth operation.

## Not enough?

For more information and use cases, see the [full documentation](https://github.com/Sology/smart_listing).

## Credits

SmartListing uses the pagination gem Kaminari: https://github.com/amatsuda/kaminari

Created by Sology: http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited: http://smartlanguageapps.com/
