(function () {
  "use strict";

  const logEl = () => document.getElementById("log");

  function log(line) {
    const el = logEl();
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
      safeRun("/healthz", () => window.AdminApi.getHealth());
    });
    document.getElementById("btn-whoami")?.addEventListener("click", () => {
      safeRun("/api/whoami", async () => {
        const token = await window.AdminAuth.acquireApiAccessToken();
        return window.AdminApi.getWhoami(token, false);
      });
    });

    log("Set APP_ env vars (or edit js/config.js) with Entra app ids and scopes. API must allow CORS for this origin.");
  });
})();
