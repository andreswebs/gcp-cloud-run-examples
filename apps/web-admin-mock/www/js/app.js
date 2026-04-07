(function () {
  "use strict";

  function log(line) {
    const el = document.getElementById("log");
    if (el) {
      el.textContent += `${new Date().toISOString()} ${line}\n`;
    }
  }

  async function safeRun(label, fn) {
    try {
      const r = await fn();
      log(`${label} OK${r !== undefined ? ` ${JSON.stringify(r)}` : ""}`);
    } catch (e) {
      log(`${label} FAIL ${e && e.message ? e.message : e}`);
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("btn-sign-in")?.addEventListener("click", () => {
      safeRun("sign-in", () => window.AdminAuth.signInPopup());
    });
    document.getElementById("btn-sign-out")?.addEventListener("click", () => {
      safeRun("sign-out", () => window.AdminAuth.signOut());
    });

    document.getElementById("btn-health")?.addEventListener("click", () => {
      safeRun("/health", () => window.AdminApi.getHealth());
    });
    document.getElementById("btn-whoami-auth")?.addEventListener("click", () => {
      safeRun("/api/whoami (Authorization)", async () => {
        const token = await window.AdminAuth.acquireApiAccessToken();
        return window.AdminApi.getWhoami(token, false);
      });
    });
    document.getElementById("btn-whoami-forwarded")?.addEventListener("click", () => {
      safeRun("/api/whoami (X-Forwarded-Authorization)", async () => {
        const token = await window.AdminAuth.acquireApiAccessToken();
        return window.AdminApi.getWhoami(token, true);
      });
    });

    log("Set APP_ env vars (or edit js/config.js) with Entra app ids and scopes. API must allow CORS for this origin.");
  });
})();
