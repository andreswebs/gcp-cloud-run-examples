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

  function hasFirebaseConfig() {
    const env = window.__ENV__ || {};
    return !!(env.FIREBASE_PROJECT_ID && env.FIREBASE_API_KEY);
  }

  document.addEventListener("DOMContentLoaded", () => {
    const btnSignIn = document.getElementById("btn-sign-in-google");
    const btnSignOut = document.getElementById("btn-sign-out");

    if (!hasFirebaseConfig()) {
      if (btnSignIn) btnSignIn.disabled = true;
      if (btnSignOut) btnSignOut.disabled = true;
      log("Firebase config missing — set APP_FIREBASE_API_KEY and APP_FIREBASE_PROJECT_ID (or edit js/config.js). Sign-in is disabled.");
    }

    btnSignIn?.addEventListener("click", () => {
      safeRun("sign-in Google", () => window.AppAuth.signInWithGoogle());
    });
    btnSignOut?.addEventListener("click", () => {
      safeRun("sign-out", () => window.AppAuth.signOut());
    });

    document.getElementById("btn-health")?.addEventListener("click", () => {
      safeRun("/healthz", () => window.AppApi.getHealth());
    });
    document.getElementById("btn-whoami-auth")?.addEventListener("click", () => {
      safeRun("/api/whoami (Authorization)", async () => {
        const token = await window.AppAuth.getIdToken();
        return window.AppApi.getWhoami(token, false);
      });
    });
    document.getElementById("btn-whoami-forwarded")?.addEventListener("click", () => {
      safeRun("/api/whoami (X-Forwarded-Authorization)", async () => {
        const token = await window.AppAuth.getIdToken();
        return window.AppApi.getWhoami(token, true);
      });
    });
    document.getElementById("btn-connectivity")?.addEventListener("click", () => {
      safeRun("/api/internal/connectivity", async () => {
        const token = await window.AppAuth.getIdToken();
        return window.AppApi.getConnectivity(token);
      });
    });
  });
})();
