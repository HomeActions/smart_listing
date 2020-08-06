import Rails from "@rails/ujs"
import SmartListing from "./sl_one"

// endsWith polyfill
if (!String.prototype.endsWith) {
    String.prototype.endsWith = function(search, this_len) {
        if ((this_len === undefined) || (this_len > this.length)) {
            this_len = this.length;
        }
        return this.substring(this_len - (search.length), this_len) === search;
    };
}

// Useful when SmartListing target url is different than current one
Rails.href = element => element.attr("href") || element.data("<%= SmartListing.config.data_attributes(:href) %>") || window.location.pathname;

const ready = function() {
    let elem = document.getElementsByClassName(SmartListing.config.class_name("main"))[0];
    let controls = document.getElementsByClassName(SmartListing.config.class_name("controls"));
    elem.smart_listing();
    return controls.smart_listing_controls();
};

document.addEventListener("DOMContentLoaded", ready);
document.addEventListener("page:load turbolinks:load", ready);
