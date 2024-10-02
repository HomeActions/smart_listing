module SmartListing
  module Helper
    module ControllerExtensions
      def smart_listing_create(*args)
        options = args.extract_options!
        name = (args[0] || options[:name] || controller_name).to_sym
        collection = args[1] || options[:collection] || smart_listing_collection

        view_context = respond_to?(:controller) ? controller.view_context : self.view_context
        options = { config_profile: view_context.smart_listing_config_profile }.merge(options)

        list = SmartListing::Base.new(name, collection, options)
        list.setup(params, cookies)

        @smart_listings ||= {}
        @smart_listings[name] = list

        list.collection
      end

      def smart_listing(name)
        @smart_listings[name.to_sym]
      end

      def _prefixes
        super << 'smart_listing'
      end
    end

    class Builder
      # ... (keep the existing Builder class implementation)
    end

    def smart_listing_config_profile
      defined?(super) ? super : :default
    end

    def smart_listing_config
      SmartListing.config(smart_listing_config_profile)
    end

    def smart_listing_for(name, *args, &block)
      raise ArgumentError, "Missing block" unless block_given?
      name = name.to_sym
      options = args.extract_options!
      bare = options.delete(:bare)

      builder = Builder.new(name, @smart_listings[name], self, options, block)

      data = {
        "#{smart_listing_config.data_attributes(:max_count).gsub('_', '-')}" => @smart_listings[name].max_count,
        "#{smart_listing_config.data_attributes(:item_count).gsub('_', '-')}" => @smart_listings[name].count,
        "#{smart_listing_config.data_attributes(:href).gsub('_', '-')}" => @smart_listings[name].href,
        "#{smart_listing_config.data_attributes(:callback_href).gsub('_', '-')}" => @smart_listings[name].callback_href,
      }.compact

      data.merge!(options[:data]) if options[:data]

      if bare
        capture(builder, &block)
      else
        content_tag(:div, class: smart_listing_config.classes(:main), id: name, data: data) do
          concat(content_tag(:div, "", class: smart_listing_config.classes(:loading)))
          concat(content_tag(:div, class: smart_listing_config.classes(:content)) do
            concat(capture(builder, &block))
          end)
        end
      end
    end

    def smart_listing_render(name = controller_name, *args)
      options = args.extract_options!
      smart_listing_for(name, *args) do |smart_listing|
        concat(smart_listing.render_list(options[:locals]))
      end
    end

    def smart_listing_controls_for(name, *args, &block)
      smart_listing = @smart_listings.try(:[], name)

      classes = [smart_listing_config.classes(:controls), args.first.try(:[], :class)]

      form_tag(smart_listing.try(:href) || {}, data: { remote: smart_listing.try(:remote?) || true }, method: :get, class: classes, data: { smart_listing_config.data_attributes(:main) => name }) do
        concat(content_tag(:div, style: "margin:0;padding:0;display:inline") do
          concat(hidden_field_tag("#{smart_listing.try(:base_param)}[_]", 1, id: nil))
        end)
        concat(capture(&block))
      end
    end

    # ... (keep the rest of the existing helper methods)

  end
end
