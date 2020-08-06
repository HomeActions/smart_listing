HTMLElement.prototype.smart_listing.showPopover = function(elem, body) {
    elem.popover(SmartListing.config.bootstrap_commands("popover_destroy"));
    elem.popover({content: body, html: true, trigger: "manual"});
    return elem.popover("show");
};

HTMLElement.prototype.smart_listing.showConfirmation = function(confirmation_elem, msg, confirm_callback) {
    const buildPopover = function(confirmation_elem, msg) {
        const deletion_popover = $("<div/>").addClass("confirmation_box");
        deletion_popover.append($("<p/>").html(msg));
        return deletion_popover.append($("<p/>")
            .append($("<button/>").html("Yes").addClass("btn btn-danger ").click(event => {
                // set @confirmed element and emulate click on icon
                const editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"));
                confirm_callback(confirmation_elem);
                $(confirmation_elem).click();
                return $(confirmation_elem).popover(SmartListing.config.bootstrap_commands("popover_destroy"));
            }))
            .append(" ")
            .append($("<button/>").html("No").addClass("btn btn-small").click(event => {
                const editable = $(event.currentTarget).closest(SmartListing.config.class_name("editable"));
                return $(confirmation_elem).popover(SmartListing.config.bootstrap_commands("popover_destroy"));
            }))
        );
    };

    return HTMLElement.prototype.smart_listing.showPopover(confirmation_elem, buildPopover(confirmation_elem, msg));
};

HTMLElement.prototype.smart_listing.confirm = function(elem, msg) {
    if (!elem.data("confirmed")) {
        // We need confirmation
        HTMLElement.prototype.smart_listing.showConfirmation(elem, msg, confirm_elem => {
            return confirm_elem.data("confirmed", true);
        });
        return false;
    } else {
        // Confirmed, reset flag and go ahead with deletion
        elem.data("confirmed", false);
        return true;
    }
};

HTMLElement.prototype.smart_listing.onLoading = function(content, loader) {
    content.stop(true).fadeTo(500, 0.2);
    loader.show();
    return loader.stop(true).fadeTo(500, 1);
};

HTMLElement.prototype.smart_listing.onLoaded = function(content, loader) {
    content.stop(true).fadeTo(500, 1);
    return loader.stop(true).fadeTo(500, 0, () => {
        return loader.hide();
    });
};

HTMLElement.prototype.smart_listing_controls = function() {
    const reload = function(controls) {
        const container = $(`#${controls.data(SmartListing.config.data_attribute("main"))}`);
        const smart_listing = container.smart_listing();

        // serialize form and merge it with smart listing params
        let prms = {};
        $.each(controls.serializeArray(), function(i, field) {
            if (field.name.endsWith("[]")) {
                const field_name = field.name.slice(0, field.name.length - 2);
                if (Array.isArray(prms[field_name])) {
                    return prms[field_name].push(field.value);
                } else {
                    return prms[field_name] = [field.value];
                }
            } else {
                return prms[field.name] = field.value;
            }
        });

        prms = $.extend(smart_listing.params(), prms);
        smart_listing.params(prms);

        smart_listing.fadeLoading();
        return smart_listing.reload();
    };

    return $(this).each(function() {
        // avoid double initialization
        if ($(this).data(SmartListing.config.data_attribute("controls_initialized"))) { return; }
        $(this).data(SmartListing.config.data_attribute("controls_initialized"), true);

        const controls = $(this);
        const smart_listing = $(`#${controls.data(SmartListing.config.data_attribute("main"))}`);
        const reset = controls.find(SmartListing.config.class_name("controls_reset"));

        controls.submit(function() {
            // setup smart listing params, reload and don"t actually submit controls form
            reload(controls);
            return false;
        });

        controls.find("input, select").change(function() {
            if (!$(this).data(SmartListing.config.data_attribute("observed"))) { // do not submit controls form when changed field is observed (observing submits form by itself)
                return reload(controls);
            }
        });

        return HTMLElement.prototype.smart_listing_controls.filter(controls.find(SmartListing.config.class_name("filtering")));
    });
};

HTMLElement.prototype.smart_listing_controls.filter = function(filter) {
    const form = filter.closest("form");
    const button = form.find(SmartListing.config.selector("filtering_button"));
    const icon = form.find(SmartListing.config.selector("filtering_icon"));
    const field = form.find(SmartListing.config.selector("filtering_input"));

    HTMLElement.prototype.smart_listing.observeField(field, {
            onFilled() {
                icon.removeClass(SmartListing.config.class("filtering_search"));
                icon.addClass(SmartListing.config.class("filtering_cancel"));
                return button.removeClass(SmartListing.config.class("filtering_disabled"));
            },
            onEmpty() {
                icon.addClass(SmartListing.config.class("filtering_search"));
                icon.removeClass(SmartListing.config.class("filtering_cancel"));
                return button.addClass(SmartListing.config.class("filtering_disabled"));
            },
            onChange() {
                return form.submit();
            }
        }
    );

    return button.click(function() {
        if (field.val().length > 0) {
            field.val("");
            field.trigger("keydown");
        }
        return false;
    });
};