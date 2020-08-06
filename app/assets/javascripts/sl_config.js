import extend from "./sl_extend"

export default class Config {
  static initClass() {
    this.options = import("./config.json");
  }

  static merge(d) {
    let elem = document.getElementsByTagName("body").dataset.smartListing.config;
    return extend(true, this.options, d || elem);
  }

  static class(name){
    return this.options["constants"]["classes"][name];
  }

  static class_name(name) {
    return `.#${this.class(name)}`;
  }

  static data_attribute(name){
    return this.options["constants"]["data_attributes"][name];
  }

  static selector(name){
    return this.options["constants"]["selectors"][name];
  }

  static element_template(name){
    return this.options["constants"]["element_templates"][name];
  }

  static bootstrap_commands(name){
    return this.options["constants"]["bootstrap_commands"][name];
  }
}
Config.initClass();