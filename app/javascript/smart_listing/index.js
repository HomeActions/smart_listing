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

// Handle remote links
document.addEventListener("click", (event) => {
  const link = event.target.closest("a[data-remote='true']");
  if (link) {
    event.preventDefault();
    fetch(link.href, {
      method: "GET",
      headers: {
        "Accept": "text/javascript",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const scripts = doc.querySelectorAll("script");
      scripts.forEach(script => {
        eval(script.textContent);
      });
    });
  }
});

// Handle sorting
document.addEventListener("click", (event) => {
  const sortLink = event.target.closest("a[data-attr]");
  if (sortLink) {
    event.preventDefault();
    const url = new URL(sortLink.href);
    url.searchParams.set("sort", sortLink.dataset.attr);
    url.searchParams.set("order", sortLink.dataset.order === "asc" ? "desc" : "asc");
    fetch(url, {
      method: "GET",
      headers: {
        "Accept": "text/javascript",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const scripts = doc.querySelectorAll("script");
      scripts.forEach(script => {
        eval(script.textContent);
      });
    });
  }
});

// Handle form submissions
document.addEventListener("submit", (event) => {
  const form = event.target;
  if (form.dataset.remote === "true") {
    event.preventDefault();
    const formData = new FormData(form);
    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        "Accept": "text/javascript",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const scripts = doc.querySelectorAll("script");
      scripts.forEach(script => {
        eval(script.textContent);
      });
    });
  }
});

// Handle delete actions with confirmation
document.addEventListener("click", (event) => {
  const deleteLink = event.target.closest("a.destroy[data-method='delete']");
  if (deleteLink) {
    event.preventDefault();
    if (confirm(deleteLink.dataset.confirm || "Are you sure?")) {
      fetch(deleteLink.href, {
        method: "DELETE",
        headers: {
          "Accept": "text/javascript",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");
        const scripts = doc.querySelectorAll("script");
        scripts.forEach(script => {
          eval(script.textContent);
        });
      });
    }
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

// Handle custom SmartListing events
document.addEventListener("smart-listing:create", (event) => {
  const smartListing = event.target;
  const { id, persisted, content } = event.detail;
  smartListing.create(id, persisted, content);
});

document.addEventListener("smart-listing:new-item", (event) => {
  const smartListing = event.target;
  const { content } = event.detail;
  smartListing.newItem(content);
});

document.addEventListener("smart-listing:destroy", (event) => {
  const smartListing = event.target;
  const { id, destroyed } = event.detail;
  smartListing.destroy(id, destroyed);
});

document.addEventListener("smart-listing:edit", (event) => {
  const smartListing = event.target;
  const { id, content } = event.detail;
  smartListing.edit(id, content);
});

document.addEventListener("smart-listing:remove", (event) => {
  const smartListing = event.target;
  const { id } = event.detail;
  smartListing.remove(id);
});

document.addEventListener("smart-listing:update", (event) => {
  const smartListing = event.target;
  const { id, valid, content } = event.detail;
  smartListing.update(id, valid, content);
});