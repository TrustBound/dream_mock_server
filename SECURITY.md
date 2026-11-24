# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | ✅ Active support  |
| < 2.0   | ❌ Not supported |

Dream Mock Server is part of the Dream family. It is a test tool: run it only
in tests and local development, never as a public service.

## What Dream Mock Server Is Responsible For

Dream Mock Server is a library that gives:
- **Built-in endpoints** - Fixed responses for echo, status, compression, redirect and streaming tests
- **Config mode** - Routes that you supply, with a fixed status and body
- **Start and stop** - `start`, `start_with_config` and `stop` for a server on `localhost`
- **Routers** - `create_router` and `create_config_router` for a Dream server that you set up yourself

Dream Mock Server is **not a production server**. It answers your HTTP client
with known responses, so your tests can make sure that the client is correct.

This means its security surface is small:
- Endpoint bugs (a crash or a hang that the endpoint does not document)
- Streaming bugs (memory issues, resource exhaustion)
- A server that listens on an address other than the one you set

## What You're Responsible For

Your test setup handles:
- **Network exposure** - Keep the server on `localhost`, or on a network that only your tests can reach
- **Bind address** - If you use the routers with your own Dream server, you choose the address
- **Test data** - Do not put real secrets or personal data in config-mode routes
- **Process cleanup** - Call `stop` when the tests finish
- **TLS/HTTPS** - The mock server serves plain HTTP only

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Email: **engineering@trustbound.ai**

### What to Include

- **Type of vulnerability** (e.g., resource exhaustion in a streaming endpoint)
- **Location** in Dream Mock Server's code (file/function)
- **Steps to reproduce** with minimal example
- **Impact** - What can an attacker do?
- **Proof-of-concept** if you have one

Focus on vulnerabilities in **Dream Mock Server's code**, not in your
application code.

### What to Expect

1. **Acknowledgment** within 48 hours
2. **Assessment** within 7 days
3. **Fix** coordinated with you on timing
4. **Release** with security advisory
5. **Credit** in the advisory (if desired)

## Security in Dream Mock Server

### Type Safety

Gleam's type system prevents many vulnerabilities:
- ✅ No null pointer exceptions
- ✅ No buffer overflows
- ✅ Exhaustive pattern matching
- ✅ Immutable data structures

### What Dream Mock Server Validates

Dream Mock Server is an HTTP server for tests. It answers your HTTP client
with fixed, known responses. Use it only in tests and local development.

Do not expose it to an untrusted network. It listens on `localhost`, and it
has no authentication. If you bind it to another address with your own Dream
server, any client that can reach that address can use every endpoint.

The mock server validates only these inputs:

- **Status code** - `GET /status/:code` must get an integer, or it returns status 400
- **Routes** - a request that matches no route returns status 404
- **Config mode** - the first route that matches the path and method gives the response

### What Dream Mock Server Does Not Validate

- ❌ Request bodies: `POST /post`, `PUT /put` and `PATCH /patch` echo the body back
- ❌ Headers, except the ones that an endpoint echoes
- ❌ The range of the status code in `GET /status/:code`
- ❌ Request size and request rate
- ❌ TLS: it serves plain HTTP only

Some endpoints send slow, large, corrupted or dropped responses on purpose.
They test how your client handles failure. They are not vulnerabilities.

## Known Non-Issues

These are not Dream Mock Server vulnerabilities (they are intended behavior,
or your test setup's responsibility):

- Slow, large, corrupted or dropped responses from the endpoints that send them on purpose
- Request bodies and headers echoed back without changes
- No authentication on any endpoint
- Plain HTTP with no TLS
- A server that you bound to a public address yourself
- A server that still runs because the tests did not call `stop`

## Dependencies

Dream Mock Server's dependencies:
- **Dream** - Router, HTTP types and the server, which runs on Mist
- **gleam_erlang** and **gleam_otp** - Processes and actors on the BEAM
- **gleam_http** - HTTP types
- **gleam_json** - JSON responses
- **gleam_yielder** - Streaming response chunks
- **Gleam stdlib** - Type-safe, battle-tested
- **BEAM/OTP** - 30+ years of production use

We monitor dependencies and update promptly for security issues.

## Questions?

- **Security questions**: engineering@trustbound.ai
- **Non-security issues**: [GitHub Issues](https://github.com/TrustBound/dream_mock_server/issues)
- **General discussion**: [GitHub Discussions](https://github.com/TrustBound/dream/discussions)

---

**Remember:** Dream Mock Server is a test tool. Run it in tests, keep it off
untrusted networks, and stop it when the tests finish.
