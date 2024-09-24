import SmartListing from '../../assets/javascripts/smart_listing.js.erb'

export default SmartListing;

function initSmartListing() {
  document.querySelectorAll(SmartListing.config.class_name("main")).forEach(el => new SmartListing(el));
}

// Initialize SmartListing
document.addEventListener("DOMContentLoaded", initSmartListing);
document.addEventListener("turbo:load", initSmartListing);

// Re-initialize SmartListing after Turbo cache restoration
document.addEventListener("turbo:before-cache", () => {
  // Clean up any existing SmartListing instances if necessary
});

document.addEventListener("turbo:render", () => {
  initSmartListing();
});

// Handle Turbo form submissions
document.addEventListener("turbo:submit-start", (event) => {
  const form = event.target;
  if (form.dataset.remote === "true") {
    event.preventDefault();
    // Handle the form submission manually if needed
  }
});

// Update SmartListing after Turbo stream updates
document.addEventListener("turbo:before-stream-render", (event) => {
  const targetElement = event.target;
  if (targetElement.id && targetElement.id.includes("smart_listing")) {
    // Reinitialize SmartListing for the updated element
    new SmartListing(targetElement);
  }
});