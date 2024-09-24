require 'smart_listing/config'
require "smart_listing/engine"
require "kaminari"

# Fix parsing nested params
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for @params.deep_merge(page_param(page)).merge(only_path: true)
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
    UNSAFE_PARAMS = %i[authenticity_token commit utf8 _method script_name].freeze
    # For fast-check, like:
    #   puts variable if ALLOWED_DIRECTIONS[variable]
    ALLOWED_DIRECTIONS = %w[asc desc].concat(['']).to_h { |d| [d, true] }.freeze
    private_constant :ALLOWED_DIRECTIONS

    def initialize(name, collection, options = {})
      @name = name

      config_profile = options.delete(:config_profile)

      @options = {
        partial: @name,                       # SmartListing partial name
        sort_attributes: :implicit,           # allow implicitly setting sort attributes
        default_sort: {},                     # default sorting
        href: nil,                            # set SmartListing target url (in case when different than current url)
        remote: true,                         # SmartListing is remote by default
        callback_href: nil,                   # set SmartListing callback url (in case when different than current url)
      }.merge(SmartListing.config(config_profile).global_options).merge(options)

      @collection = options[:array] ? collection.to_a : collection
      @partial = @options[:partial]
    end

    def setup(params, cookies)
      @params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params
      @params = @params.with_indifferent_access
      @params.except!(*UNSAFE_PARAMS)

      @page = get_param(:page)
      @per_page = calculate_per_page(cookies)
      @sort = parse_sort(get_param(:sort)) || @options[:default_sort]
      sort_keys = @options[:sort_attributes] == :implicit ? @sort.keys.map { |s| [s, s] } : @options[:sort_attributes]

      set_param(:per_page, @per_page, cookies) if @options[:memorize_per_page]

      @count = @collection.is_a?(Hash) ? @collection.length : @collection.size

      adjust_page_if_needed

      apply_sorting_and_pagination(sort_keys)
    end

    def param_names
      @options[:param_names]
    end

    def param_name(key)
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

    def all_params(overrides = {})
      {base_param => @options[:param_names].transform_values { |v| overrides[v] || send(v) }}
    end

    def sort_order(attribute)
      @sort&.dig(attribute)
    end

    def base_param
      "#{name}_smart_listing"
    end

    private

    def get_param(key, store = @params)
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"]
      else
        store.dig(base_param, param_names[key])
      end
    end

    def set_param(key, value, store = @params)
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"] = value
      else
        store[base_param] ||= {}
        store[base_param][param_names[key]] = value
      end
    end

    def parse_sort(sort_params)
      return nil if sort_params.blank?

      if @options[:sort_attributes] == :implicit
        sort_params.each_with_object({}) do |(attr, dir), sort|
          key = attr.to_s if @options[:array] || @collection.klass.attribute_method?(attr)
          sort[key] = dir.to_s if key && ALLOWED_DIRECTIONS[dir.to_s]
        end
      elsif @options[:sort_attributes]
        @options[:sort_attributes].each_with_object({}) do |(k, _), sort|
          dir = sort_params[k.to_s].to_s
          sort[k] = dir if ALLOWED_DIRECTIONS[dir]
        end
      end
    end

    def calculate_per_page(cookies)
      param_per_page = get_param(:per_page)
      if param_per_page.blank?
        if @options[:memorize_per_page] && (cookie_per_page = get_param(:per_page, cookies).to_i) > 0
          cookie_per_page
        else
          page_sizes.first
        end
      else
        param_per_page.to_i
      end
    end

    def adjust_page_if_needed
      if @per_page > 0
        no_pages = (@count.to_f / @per_page.to_f).ceil
        @page = no_pages if @page.to_i > no_pages
      end
    end

    def apply_sorting_and_pagination(sort_keys)
      if @options[:array]
        apply_array_sorting(sort_keys)
        apply_array_pagination if @options[:paginate] && @per_page > 0
      else
        apply_active_record_sorting(sort_keys)
        apply_active_record_pagination if @options[:paginate] && @per_page > 0
      end
    end

    def apply_array_sorting(sort_keys)
      return unless @sort && !@sort.empty?

      i = sort_keys.index { |x| x[0] == @sort.to_h.first[0] }
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
          @sort.to_h.first[1] == "asc" ? (xval <=> yval) || (xval && !yval ? 1 : -1) : (yval <=> xval) || (yval && !xval ? 1 : -1)
        end
      end
    end

    def apply_array_pagination
      @collection = ::Kaminari.paginate_array(@collection).page(@page).per(@per_page)
      @collection = @collection.page(@collection.total_pages) if @collection.empty?
    end

    def apply_active_record_sorting(sort_keys)
      return unless @sort && !@sort.empty?

      @collection = @collection.order(sort_keys.map { |s| Arel.sql("#{s[1]} #{@sort[s[0]]}") if @sort[s[0]] }.compact)
    end

    def apply_active_record_pagination
      @collection = @collection.page(@page).per(@per_page)
    end
  end
end
