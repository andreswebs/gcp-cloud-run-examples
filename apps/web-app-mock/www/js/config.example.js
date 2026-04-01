/**
 * Runtime env config for the app mock (Firebase Auth).
 *
 * In production the entrypoint.sh script generates config.js from APP_-prefixed
 * environment variables.  For local development, copy this to config.js and fill
 * in the values.
 *
 * Environment variables (APP_ prefix is stripped at runtime):
 *   APP_API_BASE_URL                   → window.__ENV__.API_BASE_URL
 *   APP_FIREBASE_API_KEY               → window.__ENV__.FIREBASE_API_KEY
 *   APP_FIREBASE_AUTH_DOMAIN           → window.__ENV__.FIREBASE_AUTH_DOMAIN
 *   APP_FIREBASE_PROJECT_ID            → window.__ENV__.FIREBASE_PROJECT_ID
 *   APP_FIREBASE_STORAGE_BUCKET        → window.__ENV__.FIREBASE_STORAGE_BUCKET
 *   APP_FIREBASE_MESSAGING_SENDER_ID   → window.__ENV__.FIREBASE_MESSAGING_SENDER_ID
 *   APP_FIREBASE_APP_ID                → window.__ENV__.FIREBASE_APP_ID
 */
window.__ENV__ = {
  API_BASE_URL: "https://api.keeper.sandbox.particle41.ninja/a",
  FIREBASE_API_KEY: "your-api-key",
  FIREBASE_AUTH_DOMAIN: "your-project.firebaseapp.com",
  FIREBASE_PROJECT_ID: "your-project-id",
  FIREBASE_STORAGE_BUCKET: "your-project.appspot.com",
  FIREBASE_MESSAGING_SENDER_ID: "123456789",
  FIREBASE_APP_ID: "1:123:web:abc",
};
