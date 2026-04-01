(function () {
  "use strict";

  let app = null;

  function ensureFirebase() {
    if (typeof firebase === "undefined") {
      throw new Error("Firebase compat SDK not loaded");
    }
  }

  function getFirebaseConfig() {
    const env = window.__ENV__ || {};
    if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_API_KEY) {
      throw new Error("Set FIREBASE_PROJECT_ID and FIREBASE_API_KEY in config.js (or APP_ env vars)");
    }
    return {
      apiKey: env.FIREBASE_API_KEY,
      authDomain: env.FIREBASE_AUTH_DOMAIN,
      projectId: env.FIREBASE_PROJECT_ID,
      storageBucket: env.FIREBASE_STORAGE_BUCKET,
      messagingSenderId: env.FIREBASE_MESSAGING_SENDER_ID,
      appId: env.FIREBASE_APP_ID,
    };
  }

  window.AppAuth = {
    init() {
      ensureFirebase();
      if (firebase.apps.length > 0) {
        app = firebase.app();
        return;
      }
      const cfg = getFirebaseConfig();
      app = firebase.initializeApp(cfg);
      firebase.auth(app);
    },

    async signInWithGoogle() {
      this.init();
      const provider = new firebase.auth.GoogleAuthProvider();
      return await firebase.auth().signInWithPopup(provider);
    },

    async signOut() {
      if (firebase.apps.length === 0) {
        return;
      }
      return await firebase.auth().signOut();
    },

    /** @returns {Promise<string>} Firebase ID token (JWT) */
    async getIdToken() {
      this.init();
      const user = firebase.auth().currentUser;
      if (!user) {
        throw new Error("Not signed in");
      }
      return user.getIdToken(true);
    },
  };
})();
