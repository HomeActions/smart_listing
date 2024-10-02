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
      attr_reader :smart_listing_name, :smart_listing, :template, :options, :proc

      def initialize(smart_listing_name, smart_listing, template, options, proc)
        @smart_listing_name = smart_listing_name
        @smart_listing = smart_listing
        @template = template
        @options = options
        @proc = proc
      end

      def name
        smart_listing_name
      end

      def paginate(*)
        if smart_listing.collection.respond_to?(:current_page)
          template.paginate(smart_listing.collection, **{ data: { turbo_frame: smart_listing_name }, param_name: smart_listing.param_name(:page) }.merge(smart_listing.kaminari_options))
        end
      end

      def collection
        smart_listing.collection
      end

      def empty?
        smart_listing.count.zero?
      end

      def pagination_per_page_links(*)
        container_classes = [template.smart_listing_config.classes(:pagination_per_page)]
        container_classes << template.smart_listing_config.classes(:hidden) if empty?

        per_page_sizes = smart_listing.page_sizes.clone
        per_page_sizes.push(0) if smart_listing.unlimited_per_page?

        locals = {
          container_classes: container_classes,
          per_page_sizes: per_page_sizes,
        }

        template.render(partial: 'smart_listing/pagination_per_page_links', locals: default_locals.merge(locals))
      end

      def pagination_per_page_link(page)
        url = if smart_listing.per_page.to_i != page
                template.url_for(smart_listing.params.merge(smart_listing.all_params(per_page: page, page: 1)))
              end

        locals = {
          page: page,
          url: url,
        }

        template.render(partial: 'smart_listing/pagination_per_page_link', locals: default_locals.merge(locals))
      end

      def sortable(title, attribute, options = {})
        dirs = options[:sort_dirs] || smart_listing.sort_dirs || [nil, "asc", "desc"]

        next_index = dirs.index(smart_listing.sort_order(attribute)).nil? ? 0 : (dirs.index(smart_listing.sort_order(attribute)) + 1) % dirs.length

        sort_params = {
          attribute => dirs[next_index]
        }

        locals = {
          order: smart_listing.sort_order(attribute),
          url: template.url_for(smart_listing.params.merge(smart_listing.all_params(sort: sort_params))),
          container_classes: [template.smart_listing_config.classes(:sortable)],
          attribute: attribute,
          title: title,
          data: { turbo_frame: smart_listing_name }
        }

        template.render(partial: 'smart_listing/sortable', locals: default_locals.merge(locals))
      end

      def update(options = {})
        part = options.delete(:partial) || smart_listing.partial || smart_listing_name

        template.render(partial: 'smart_listing/update_list', locals: { name: smart_listing_name, part: part, smart_listing: self })
      end

      def render_list(locals = {})
        if smart_listing.partial
          template.render partial: smart_listing.partial, locals: { smart_listing: self }.merge(locals || {})
        end
      end

      def render(options = {}, locals = {}, &block)
        if locals.empty?
          options[:locals] ||= {}
          options[:locals].merge!(smart_listing: self)
        else
          locals.merge!(smart_listing: self)
        end

        template.render options, locals, &block
      end

      def item_new(options = {}, &block)
        no_records_classes = [template.smart_listing_config.classes(:no_records)]
        no_records_classes << template.smart_listing_config.classes(:hidden) unless empty?
        new_item_button_classes = []
        new_item_button_classes << template.smart_listing_config.classes(:hidden) if max_count?

        locals = {
          colspan: options.delete(:colspan),
          no_items_classes: no_records_classes,
          no_items_text: options.delete(:no_items_text) || template.t("smart_listing.msgs.no_items"),
          new_item_button_url: options.delete(:link),
          new_item_button_classes: new_item_button_classes,
          new_item_button_text: options.delete(:text) || template.t("smart_listing.actions.new"),
          new_item_autoshow: block_given?,
          new_item_content: nil,
        }

        if block_given?
          locals[:placeholder_classes] = [template.smart_listing_config.classes(:new_item_placeholder)]
          locals[:placeholder_classes] << template.smart_listing_config.classes(:hidden) if !empty? && max_count?
          locals[:new_item_action_classes] = [template.smart_listing_config.classes(:new_item_action), template.smart_listing_config.classes(:hidden)]

          locals[:new_item_content] = template.capture(&block)
        else
          locals[:placeholder_classes] = [template.smart_listing_config.classes(:new_item_placeholder), template.smart_listing_config.classes(:hidden)]
          locals[:new_item_action_classes] = [template.smart_listing_config.classes(:new_item_action)]
          locals[:new_item_action_classes] << template.smart_listing_config.classes(:hidden) if !empty? && max_count?
        end

        template.render(partial: 'smart_listing/item_new', locals: default_locals.merge(locals))
      end

      def count
        smart_listing.count
      end

      def max_count?
        smart_listing.max_count && smart_listing.count >= smart_listing.max_count
      end

      private

      def default_locals
        { smart_listing: smart_listing, builder: self }
      end
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
        controller: "smart-listing",
        smart_listing_config.data_attributes(:max_count) => @smart_listings[name].max_count,
        smart_listing_config.data_attributes(:item_count) => @smart_listings[name].count,
        smart_listing_config.data_attributes(:href) => @smart_listings[name].href,
        smart_listing_config.data_attributes(:callback_href) => @smart_listings[name].callback_href,
      }.compact

      data.merge!(options[:data]) if options[:data]

      if bare
        capture(builder, &block)
      else
        content_tag(:div, class: smart_listing_config.classes(:main), id: name, data: data) do
          concat(content_tag(:div, "", class: smart_listing_config.classes(:loading)))
          concat(content_tag(:turbo-frame, id: name) do
            concat(content_tag(:div, class: smart_listing_config.classes(:content)) do
              concat(capture(builder, &block))
            end)
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

      form_tag(smart_listing.try(:href) || {}, data: { turbo_frame: name, controller: "smart-listing-form" }, method: :get, class: classes) do
        concat(content_tag(:div, style: "margin:0;padding:0;display:inline") do
          concat(hidden_field_tag("#{smart_listing.try(:base_param)}[_]", 1, id: nil))
        end)
        concat(capture(&block))
      end
    end

    def smart_listing_item_actions(actions = [])
      content_tag(:span) do
        actions.each do |action|
          next unless action.is_a?(Hash)

          locals = {
            action_if: action.fetch(:if, true),
            url: action.delete(:url),
            icon: action.delete(:icon),
            title: action.delete(:title),
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
            locals[:confirmation] = action.delete(:confirmation)
            template = 'action_delete'
          when :custom
            locals[:html_options] = action
            template = 'action_custom'
          end

          locals[:icon] = [locals[:icon], smart_listing_config.classes(:muted)] unless locals[:action_if]

          if template
            concat(render(partial: "smart_listing/#{template}", locals: locals))
          else
            concat(render(partial: "smart_listing/action_#{action_name}", locals: { action: action }))
          end
        end
      end
    end

    def smart_listing_limit_left(name)
      name = name.to_sym
      smart_listing = @smart_listings[name]

      smart_listing.max_count - smart_listing.count
    end

    def smart_listing_update(*args)
      options = args.extract_options!
      name = (args[0] || options[:name] || controller_name).to_sym
      smart_listing = @smart_listings[name]

      return unless options[:force] || (params.keys.select { |k| k.include?("smart_listing") }.present? && params[smart_listing.base_param])

      builder = Builder.new(name, smart_listing, self, {}, nil)
      render(partial: 'smart_listing/update_list', locals: {
        name: smart_listing.name,
        part: smart_listing.partial,
        smart_listing: builder,
        smart_listing_data: {
          smart_listing_config.data_attributes(:params) => smart_listing.all_params,
          smart_listing_config.data_attributes(:max_count) => smart_listing.max_count,
          smart_listing_config.data_attributes(:item_count) => smart_listing.count,
        },
        locals: options[:locals] || {}
      })
    end

    def smart_listing_item(*args)
      options = args.extract_options!
      if [:create, :create_continue, :destroy, :edit, :new, :remove, :update].include?(args[1])
        name, item_action, object, partial = args
      else
        name = (options[:name] || controller_name).to_sym
        item_action, object, partial = args
      end
      id = options[:id] || object.try(:id)
      valid = options[:valid] if options.key?(:valid)
      object_key = options.delete(:object_key) || :object
      new = options.delete(:new)

      render(partial: "smart_listing/item/#{item_action}", locals: { name: name, id: id, valid: valid, object_key: object_key, object: object, part: partial, new: new })
    end
  end
end