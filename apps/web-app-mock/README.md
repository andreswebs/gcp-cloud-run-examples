# web-app-mock

Static customers app POC — Firebase Authentication calling `dotnet-api-firebase`.

## Run locally with Docker

```sh
export APP_API_BASE_URL="<firebase-api-base-url>"
export APP_FIREBASE_API_KEY="<firebase-api-key>"
export APP_FIREBASE_AUTH_DOMAIN="<firebase-auth-domain>"
export APP_FIREBASE_PROJECT_ID="<firebase-project-id>"
export APP_FIREBASE_STORAGE_BUCKET="<firebase-storage-bucket>"
export APP_FIREBASE_MESSAGING_SENDER_ID="<firebase-messaging-sender-id>"
export APP_FIREBASE_APP_ID="<firebase-app-id>"
```

```sh
docker build -t web-app-mock .
```

```sh
docker run --rm -p 3091:8080 \
  -e APP_API_BASE_URL \
  -e APP_FIREBASE_API_KEY \
  -e APP_FIREBASE_AUTH_DOMAIN \
  -e APP_FIREBASE_PROJECT_ID \
  -e APP_FIREBASE_STORAGE_BUCKET \
  -e APP_FIREBASE_MESSAGING_SENDER_ID \
  -e APP_FIREBASE_APP_ID \
  web-app-mock
```

Open <http://localhost:3091>.

The `entrypoint-wrapper.sh` script generates `js/config.js` from `APP_`-prefixed environment variables at container startup (the prefix is stripped). See `config.example.js` for the full list of keys.
