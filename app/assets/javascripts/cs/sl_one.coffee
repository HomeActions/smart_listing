class window.SmartListing
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
