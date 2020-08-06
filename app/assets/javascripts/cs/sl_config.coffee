class Config
  @options: "<%= SmartListing.config.dump_json %>"

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