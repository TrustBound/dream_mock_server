# Non-streaming endpoints

This guide is the reference for the non-streaming endpoints of the default server that `server.start` starts. Each endpoint sends its whole body in one response.

## `GET /get`

**Returns JSON with request info**

- Returns: `{"method": "GET", "url": "/get", "query": "<raw query string>", "headers": []}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing GET requests, JSON parsing

## `POST /post`

**Echoes request body as JSON**

- Returns: `{"method": "POST", "url": "/post", "data": "<request body>"}`
- Status: 201 Created
- Content-Type: `application/json`

**Use for:** Testing POST requests, request body handling

## `PUT /put`

**Echoes request body as JSON**

- Returns: `{"method": "PUT", "url": "/put", "data": "<request body>"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing PUT requests

## `DELETE /delete`

**Returns success response**

- Returns: `{"method": "DELETE", "url": "/delete"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing DELETE requests

## `GET /json`

**Returns simple JSON object**

- Returns: `{"message": "Hello, World!", "success": true}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing JSON parsing, simple responses

## `GET /text`

**Returns plain text**

- Returns: `"Hello, World!"`
- Status: 200 OK
- Content-Type: `text/plain`

**Use for:** Testing text responses

## `GET /uuid`

**Returns UUID-like string**

- Returns: `{"uuid": "123e4567-e89b-12d3-a456-426614174000"}`
- Status: 200 OK
- Content-Type: `application/json`

**Use for:** Testing small JSON responses

## `GET /`

**Info page**: lists all available endpoints with descriptions

**Use for:** Documentation, service discovery

## See also

- [Getting started](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/getting-started.md): install the package and run a first test body against the server
- [Run the server](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/run-the-server.md): standalone mode, start and stop from Gleam, and use in integration tests
- [Config mode](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/config-mode.md): give each path your own status and body
- [Streaming endpoints](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/streaming-endpoints.md): the endpoint reference for the chunked streams
- [How it works](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/how-it-works.md): streaming technique, timing, architecture and dependencies
- [README](https://github.com/TrustBound/dream_mock_server/blob/main/README.md)
