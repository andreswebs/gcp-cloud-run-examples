# web-admin-mock

Static admin portal POC — MSAL (Entra ID) authentication calling `dotnet-api-entra` and `dotnet-api-firebase`.

## Run locally with Docker

```sh
export APP_API_BASE_URL="<api-base-url>"
export APP_MSAL_CLIENT_ID="<msal-client-id>"
export APP_MSAL_AUTHORITY="<msal-authority>"
export APP_API_SCOPES="<api-scopes>"
```

```sh
docker build -t web-admin-mock .
```

```sh
docker run --rm -p 3090:8080 \
  -e APP_API_BASE_URL \
  -e APP_MSAL_CLIENT_ID \
  -e APP_MSAL_AUTHORITY \
  -e APP_API_SCOPES \
  web-admin-mock
```

Open <http://localhost:3090>.

The `entrypoint-wrapper.sh` script generates `js/config.js` from `APP_`-prefixed environment variables at container startup (the prefix is stripped). See `config.example.js` for the full list of keys.
