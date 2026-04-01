(function () {
  "use strict";

  async function requestJson(baseUrl, path, bearerToken, headerName) {
    const url = `${baseUrl.replace(/\/$/, "")}${path.startsWith("/") ? path : `/${path}`}`;
    const headers = { Accept: "application/json" };
    if (bearerToken) {
      const value = `Bearer ${bearerToken}`;
      if (headerName === "X-Forwarded-Authorization") {
        headers["X-Forwarded-Authorization"] = value;
      } else {
        headers.Authorization = value;
      }
    }
    const res = await fetch(url, { headers, credentials: "omit" });
    const text = await res.text();
    let body;
    try {
      body = text ? JSON.parse(text) : null;
    } catch {
      body = text;
    }
    return { ok: res.ok, status: res.status, body };
  }

  function env(key, fallback) {
    return (window.__ENV__ || {})[key] || fallback;
  }

  window.AppApi = {
    requestJson,

    getHealth() {
      return requestJson(env("API_BASE_URL", "http://localhost:8080"), "/healthz", null, "Authorization");
    },

    getWhoami(token, useForwarded) {
      return requestJson(
        env("API_BASE_URL", "http://localhost:8080"),
        "/api/whoami",
        token,
        useForwarded ? "X-Forwarded-Authorization" : "Authorization",
      );
    },

    getConnectivity(token) {
      return requestJson(
        env("API_BASE_URL", "http://localhost:8080"),
        "/api/internal/connectivity",
        token,
        "Authorization",
      );
    },
  };
})();
