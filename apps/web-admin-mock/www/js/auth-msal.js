/* global msal */

(function () {
  "use strict";

  let pca = null;
  let initDone = false;

  function ensureMsalLoaded() {
    if (typeof msal === "undefined" || !msal.PublicClientApplication) {
      throw new Error("msal-browser not loaded (check script tag)");
    }
  }

  async function ensureReady() {
    ensureMsalLoaded();
    if (initDone) {
      return;
    }
    const env = window.__ENV__ || {};
    if (!env.MSAL_CLIENT_ID || !env.MSAL_AUTHORITY) {
      throw new Error("Set MSAL_CLIENT_ID and MSAL_AUTHORITY in config.js (or APP_ env vars)");
    }

    pca = new msal.PublicClientApplication({
      auth: {
        clientId: env.MSAL_CLIENT_ID,
        authority: env.MSAL_AUTHORITY,
        redirectUri: window.location.origin + "/redirect.html",
      },
      cache: { cacheLocation: "sessionStorage", storeAuthStateInCookie: false },
    });
    await pca.initialize();
    initDone = true;
  }

  function getApiScopes() {
    const raw = (window.__ENV__ || {}).API_SCOPES || "";
    const scopes = raw.split(",").map((s) => s.trim()).filter(Boolean);
    if (scopes.length === 0) {
      throw new Error("Set API_SCOPES in config.js (or APP_API_SCOPES env var)");
    }
    return scopes;
  }

  window.AdminAuth = {
    async signInPopup() {
      await ensureReady();
      const scopes = getApiScopes();
      const result = await pca.loginPopup({ scopes });
      const accounts = pca.getAllAccounts();
      if (accounts.length > 0) {
        pca.setActiveAccount(accounts[0]);
      }
      return result;
    },

    async signOut() {
      if (!pca || !initDone) {
        return;
      }
      const account = pca.getActiveAccount() || pca.getAllAccounts()[0];
      if (account) {
        return await pca.logoutPopup({
          account,
          postLogoutRedirectUri: window.location.origin + "/redirect.html",
        });
      }
    },

    /** @returns {Promise<string>} access token for Entra-protected API */
    async acquireApiAccessToken() {
      await ensureReady();
      const account = pca.getActiveAccount() || pca.getAllAccounts()[0];
      if (!account) {
        throw new Error("Not signed in");
      }
      const scopes = getApiScopes();
      const result = await pca.acquireTokenSilent({
        account,
        scopes,
      });
      return result.accessToken;
    },
  };
})();
