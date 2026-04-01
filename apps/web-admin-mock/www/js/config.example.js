/**
 * Runtime env config for the admin mock (MSAL / Entra).
 *
 * In production the entrypoint-wrapper.sh script generates config.js from
 * APP_-prefixed environment variables.  For local development, copy this to
 * config.js and fill in the values.
 *
 * Environment variables (APP_ prefix is stripped at runtime):
 *   APP_API_BASE_URL   → window.__ENV__.API_BASE_URL
 *   APP_MSAL_CLIENT_ID → window.__ENV__.MSAL_CLIENT_ID
 *   APP_MSAL_AUTHORITY → window.__ENV__.MSAL_AUTHORITY
 *   APP_API_SCOPES     → window.__ENV__.API_SCOPES (comma-separated)
 */
window.__ENV__ = {
  API_BASE_URL: "https://api.keeper.sandbox.particle41.ninja/b",
  MSAL_CLIENT_ID: "00000000-0000-0000-0000-000000000000",
  MSAL_AUTHORITY: "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000",
  API_SCOPES: "api://00000000-0000-0000-0000-000000000000/access_as_user",
};
