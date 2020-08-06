import Config from "./sl_config"
import Rails from "@rails/ujs"

const Cls = (window.SmartListing = class SmartListing {
  static initClass() {
    this.config = Config;
  }

  constructor(e) {
    this.fadeLoading = this.fadeLoading.bind(this);
    this.fadeLoaded = this.fadeLoaded.bind(this);
    this.itemCount = this.itemCount.bind(this);
    this.maxCount = this.maxCount.bind(this);
    this.setAutoshow = this.setAutoshow.bind(this);
    this.changeItemCount = this.changeItemCount.bind(this);
    this.cancelEdit = this.cancelEdit.bind(this);
    this.refresh = this.refresh.bind(this);
    this.reload = this.reload.bind(this);
    this.params = this.params.bind(this);
    this.registerPopover = this.registerPopover.bind(this);
    this.editable = this.editable.bind(this);
    this.new_item = this.new_item.bind(this);
    this.create = this.create.bind(this);
    this.edit = this.edit.bind(this);
    this.update = this.update.bind(this);
    this.destroy = this.destroy.bind(this);
    this.remove = this.remove.bind(this);
    this.update_list = this.update_list.bind(this);
    this.container = e;
    this.name = this.container.attr("id");
    this.loading = this.container.find(SmartListing.config.class_name("loading"));
    this.content = this.container.find(SmartListing.config.class_name("content"));
    this.status = $(`${SmartListing.config.class_name("status")} [data-${SmartListing.config.data_attribute("main")}='${this.name}']`);
    this.confirmed = null;
    this.popovers = {};

    this.container.on("ajax:before", `${SmartListing.config.class_name("item_actions")}, ${SmartListing.config.class_name("pagination_container")}`, e => {
      return this.fadeLoading();
    });

    this.container.on("ajax:success", e => {
      if ($(e.target).is(`${SmartListing.config.class_name("item_actions")} ${SmartListing.config.selector("item_action_destroy")}`)) {
        // handle HEAD OK response for deletion request
        const editable = $(e.target).closest(SmartListing.config.class_name("editable"));
        if (this.container.find(SmartListing.config.class_name("editable")).length === 1) {
          this.reload();
          return false;
        } else {
          editable.remove();

          this.container.trigger("smart_listing:destroy", editable);
        }

        this.changeItemCount(-1);
        this.refresh();

        this.fadeLoaded();
        return false;
      }
    });

    this.container.on("click", SmartListing.config.selector("edit_cancel"), event => {
      const editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"));
      if(editable.length > 0) {
        // Cancel edit
        this.cancelEdit(editable);
      } else {
        // Cancel new record
        this.container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"));
        this.container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"));
      }

      this.setAutoshow(false);
      return false;
    });

    this.container.on("click", `${SmartListing.config.class_name("item_actions")} a[data-${SmartListing.config.data_attribute("confirmation")}]`, event => {
      return $.fn.smart_listing.confirm($(event.currentTarget), $(event.currentTarget).data(SmartListing.config.data_attribute("confirmation")));
    });

    this.container.on("click", `${SmartListing.config.class_name("item_actions")} a[data-${SmartListing.config.data_attribute("popover")}]`, event => {
      const name = $(event.currentTarget).data(SmartListing.config.data_attribute("popover"));
      if (jQuery.isFunction(this.popovers[name])) {
        this.popovers[name]($(event.currentTarget));
        return false;
      }
    });


    this.container.on("click", `input[type=text]${SmartListing.config.class_name("autoselect")}`, function(event) {
      return $(this).select();
    });

    this.container.on("change", SmartListing.config.class_name("callback"), event => {
      const checkbox = $(event.currentTarget);
      const id = checkbox.closest(SmartListing.config.selector("row")).data(SmartListing.config.data_attribute("id"));
      const data = {};
      data[checkbox.val()] = checkbox.is(":checked");
      return $.ajax({
        beforeSend(xhr, settings) {
          return xhr.setRequestHeader("accept", "*/*;q=0.5, " + settings.accepts.script);
        },
        url: this.container.data(SmartListing.config.data_attribute("callback_href")),
        type: "POST",
        data,
      });
    });
  }

  fadeLoading() {
    return HTMLElement.prototype.smart_listing.onLoading(this.content, this.loading);
  }

  fadeLoaded() {
    return HTMLElement.prototype.smart_listing.onLoaded(this.content, this.loading);
  }

  itemCount() {
    return parseInt(this.container.data(SmartListing.config.data_attribute("item_count")));
  }

  maxCount() {
    return parseInt(this.container.data(SmartListing.config.data_attribute("max_count")));
  }

  setAutoshow(v) {

    return this.container.data(SmartListing.config.data_attribute("autoshow"), v);
  }

  changeItemCount(value) {
    const count = this.container.data(SmartListing.config.data_attribute("item_count")) + value;
    this.container.data(SmartListing.config.data_attribute("item_count"), count);
    return this.container.find(SmartListing.config.selector("pagination_count")).html(count);
  }

  cancelEdit(editable) {
    if (editable.data(SmartListing.config.data_attribute("inline_edit_backup"))) {
      editable.html(editable.data(SmartListing.config.data_attribute("inline_edit_backup")));
      editable.removeClass(SmartListing.config.class("inline_editing"));
      return editable.removeData(SmartListing.config.data_attribute("inline_edit_backup"));
    }
  }

  // Callback called when record is added/deleted using ajax request
  refresh() {
    const header = this.content.find(SmartListing.config.selector("head"));
    const footer = this.content.find(SmartListing.config.class_name("pagination_per_page"));
    const no_records = this.content.find(SmartListing.config.class_name("no_records"));

    if (this.itemCount() === 0) {
      header.hide();
      footer.hide();
      no_records.show();
    } else {
      header.show();
      footer.show();
      no_records.hide();
    }

    if (this.maxCount()) {
      if (this.itemCount() >= this.maxCount()) {
        this.container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"));
        this.container.find(SmartListing.config.class_name("new_item_action")).addClass(SmartListing.config.class("hidden"));
      } else {
        if (this.container.data(SmartListing.config.data_attribute("autoshow"))) {
          this.container.find(SmartListing.config.class_name("new_item_placeholder")).removeClass(SmartListing.config.class("hidden"));
          this.container.find(SmartListing.config.class_name("new_item_action")).addClass(SmartListing.config.class("hidden"));
        } else {
          this.container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"));
          this.container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"));
        }
      }
    }

    return this.status.each((index, status) => {
      $(status).find(SmartListing.config.class_name("limit")).html(this.maxCount() - this.itemCount());
      if ((this.maxCount() - this.itemCount()) === 0) {
        return $(status).find(SmartListing.config.class_name("limit_alert")).show();
      } else {
        return $(status).find(SmartListing.config.class_name("limit_alert")).hide();
      }
    });
  }

  // Trigger AJAX request to reload the list
  reload() {
    return Rails.handleRemote(this.container);
  }

  params(value) {
    if (value) {
      return this.container.data(SmartListing.config.data_attribute("params"), value);
    } else {
      return this.container.data(SmartListing.config.data_attribute("params"));
    }
  }

  registerPopover(name, callback) {
    return this.popovers[name] = callback;
  }

  editable(id) {
    return this.container.find(`${SmartListing.config.class_name("editable")}[data-${SmartListing.config.data_attribute("id")}=${id}]`);
  }

  //################################################################################################
  // Methods executed by rails UJS:

  new_item(content) {
    if (!this.maxCount() || (this.itemCount() < this.maxCount())) {
      const new_item_action = this.container.find(SmartListing.config.class_name("new_item_action"));
      const new_item_placeholder = this.container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"));

      this.container.find(SmartListing.config.class_name("editable")).each((i, v) => {
        return this.cancelEdit($(v));
      });

      new_item_action.addClass(SmartListing.config.class("hidden"));
      new_item_placeholder.removeClass(SmartListing.config.class("hidden"));
      new_item_placeholder.html(content);
      new_item_placeholder.addClass(SmartListing.config.class("inline_editing"));

      this.container.trigger("smart_listing:new", new_item_placeholder);

      return this.fadeLoaded();
    }
  }

  create(id, success, content) {
    const new_item_action = this.container.find(SmartListing.config.class_name("new_item_action"));
    const new_item_placeholder = this.container.find(SmartListing.config.class_name("new_item_placeholder"));

    if (success) {
      new_item_placeholder.addClass(SmartListing.config.class("hidden"));
      new_item_action.removeClass(SmartListing.config.class("hidden"));

      const new_item = $(SmartListing.config.element_template("row")).addClass(SmartListing.config.class("editable"));
      new_item.attr(`data-${SmartListing.config.data_attribute("id")}`, id);
      new_item.html(content);

      if (new_item_placeholder.length !== 0) {
        if (new_item_placeholder.data("insert-mode") === "after") {
          new_item_placeholder.after(new_item);
        } else {
          new_item_placeholder.before(new_item);
        }
      } else {
        this.content.append(new_item);
      }

      this.container.trigger("smart_listing:create:success", new_item);

      this.changeItemCount(1);
      this.refresh();
    } else {
      new_item_placeholder.html(content);

      this.container.trigger("smart_listing:create:fail", new_item_placeholder);
    }

    return this.fadeLoaded();
  }

  edit(id, content) {
    this.container.find(SmartListing.config.class_name("editable")).each((i, v) => {
      return this.cancelEdit($(v));
    });
    this.container.find(SmartListing.config.class_name("new_item_placeholder")).addClass(SmartListing.config.class("hidden"));
    this.container.find(SmartListing.config.class_name("new_item_action")).removeClass(SmartListing.config.class("hidden"));

    const editable = this.editable(id);
    editable.data(SmartListing.config.data_attribute("inline_edit_backup"), editable.html());
    editable.html(content);
    editable.addClass(SmartListing.config.class("inline_editing"));

    this.container.trigger("smart_listing:edit", editable);

    return this.fadeLoaded();
  }

  update(id, success, content) {
    const editable = this.editable(id);
    if (success) {
      editable.removeClass(SmartListing.config.class("inline_editing"));
      editable.removeData(SmartListing.config.data_attribute("inline_edit_backup"));
      editable.html(content);

      this.container.trigger("smart_listing:update:success", editable);

      this.refresh();
    } else {
      editable.html(content);

      this.container.trigger("smart_listing:update:fail", editable);
    }

    return this.fadeLoaded();
  }

  destroy(id, destroyed) {}
  // No need to do anything here, already handled by ajax:success handler

  remove(id) {
    const editable = this.editable(id);
    editable.remove();

    return this.container.trigger("smart_listing:remove", editable);
  }

  update_list(content, data) {
    this.container.data(SmartListing.config.data_attribute("params"), $.extend(this.container.data(SmartListing.config.data_attribute("params")), data[SmartListing.config.data_attribute("params")]));
    this.container.data(SmartListing.config.data_attribute("max_count"), data[SmartListing.config.data_attribute("max_count")]);
    this.container.data(SmartListing.config.data_attribute("item_count"), data[SmartListing.config.data_attribute("item_count")]);

    this.content.html(content);

    this.refresh();
    this.fadeLoaded();

    return this.container.trigger("smart_listing:update_list", this.container);
  }
});
Cls.initClass();
