# Contributing to Dream Mock Server

Thank you for your interest in contributing to Dream Mock Server! We're excited to have you here.

Dream Mock Server is part of the Dream family. It follows Dream's coding, testing and documentation standards, which live in the [Dream repository](https://github.com/TrustBound/dream/tree/3.0.0).

## Quick Links

📖 **[Full Contributing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md)** - Detailed contribution guidelines  
🧪 **[Testing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/testing.md)** - How Dream projects are tested  
📦 **[Publishing Strategy](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/publishing.md)** - Module versioning and releases  
✍️ **[Tone Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/tone-guide.md)** - Documentation writing style  
🤝 **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community standards  
🔒 **[Security Policy](SECURITY.md)** - Reporting security vulnerabilities

## Quick Start for Contributors

### Prerequisites

- Gleam 1.19.2 or later
- Erlang/OTP 27 or later, with the JIT (the tests measure line coverage)

### Development Setup

1. **Fork and clone:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/dream_mock_server.git
   cd dream_mock_server
   ```

2. **Run tests:**
   ```bash
   make test                # All tests, with line coverage
   make check               # Format check, build, tests and docs build
   ```

3. **Make your changes:**
   - Write code following Dream's [design principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md)
   - Add tests for new functionality
   - Update documentation as needed

4. **Format and verify:**
   ```bash
   gleam format             # Format code
   make check               # Ensure everything passes
   ```

5. **Submit a pull request:**
   - Clear description of changes
   - Reference any related issues
   - Ensure CI passes

## What Can I Contribute?

### 🐛 Bug Reports
Found a bug? [Open an issue](https://github.com/TrustBound/dream_mock_server/issues/new) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (Gleam version, OS, etc.)

### 💡 Feature Requests
Have an idea? [Open an issue](https://github.com/TrustBound/dream_mock_server/issues/new) with:
- Clear use case
- Proposed API or behavior
- Why this fits Dream's philosophy

### 📝 Documentation
Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add examples
- Improve guides

### 🔧 Code Contributions
- Fix bugs
- Implement approved features
- Improve performance
- Add tests

## Code Standards

Dream Mock Server follows Dream's strict coding standards. Please read:
- **[Design Principles](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/design-principles.md)** - The "why" behind Dream
- **[Naming Conventions](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/reference/naming-conventions.md)** - Code style rules

Key principles:
- **No magic** - Everything explicit
- **No closures** - All dependencies are parameters
- **Full words** - No abbreviations (except standard ones)
- **100% test coverage** - For all code in `src/`
- **Black box testing** - Test public interfaces only

## Development Workflow

1. **Create a branch:**
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/issue-123
   ```

2. **Make focused commits:**
   ```bash
   git commit -m "Add a redirect endpoint"
   ```

3. **Keep your fork updated:**
   ```bash
   git remote add upstream https://github.com/TrustBound/dream_mock_server.git
   git fetch upstream
   git rebase upstream/main
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/my-feature
   ```

## How the Code Is Organized

The mock server has a pure core and a thin adapter. The core decides the answer to each request and has no socket, so its tests call it directly. The adapter connects the core to [dream_http_server](https://hexdocs.pm/dream_http_server), the HTTP server. It sends a whole body with a `content-length` header, and a streamed body as a chunked response.

```text
src/
├── standalone.gleam                    # Standalone entry point (port 3004)
├── compression_ffi.erl                 # zlib compression
├── dream_mock_server_ffi.erl           # Port check and server stop
└── dream_mock_server/
    ├── server.gleam                    # Programmatic start/stop functions
    ├── config.gleam                    # Config mode route types
    ├── compression.gleam               # Compression helpers
    ├── internal/
    │   ├── message.gleam               # Request and response types of the core
    │   ├── routes.gleam                # Route match: which endpoint answers
    │   ├── path.gleam                  # Path segments for the route match
    │   ├── api_endpoints.gleam         # Non-streaming endpoints
    │   ├── stream_endpoints.gleam      # Streaming endpoints and the info page
    │   ├── config_endpoint.gleam       # Config mode endpoint
    │   ├── mist_adapter.gleam          # Converts between the core and the server
    │   └── standalone_runner.gleam     # Runs the server for standalone.main
    └── views/
        ├── api_view.gleam              # JSON and text bodies
        └── index_view.gleam            # Info page text
```

The modules in `internal/` are not part of the public API.

A streaming endpoint returns a `Yielder(BitArray)`. The adapter sends one chunk for each element, and asks for the next element only after it sent the last one, so a `process.sleep` in the yielder sets the pause before each chunk. The [Endpoint reference](https://github.com/TrustBound/dream_mock_server/blob/main/docs/guides/endpoint-reference.md#how-streams-are-timed) shows the code of `/stream/fast`.

The runtime dependencies:

- **dream_http_server**: the HTTP server (a fork of mist)
- **gleam_http**: HTTP methods
- **gleam_erlang**: process control (sleep)
- **gleam_otp**: the start error type
- **gleam_json**: JSON encoding
- **gleam_yielder**: stream generation

The mock server does not depend on the Dream web framework.

## Testing Requirements

All contributions must include tests:

- **Unit tests** - Fast, isolated, deterministic
- **Server tests** - Start the server on a free port and send real requests
- **Gherkin scenarios** - `test/features/mock_server.feature`, with step definitions in `test/features/mock_server_feature.gleam`; dream_test runs them inside `gleam test`. Each scenario starts the server on a free port, sends real HTTP requests to it and stops it. The scenarios check the status codes, the content format, the chunk counts and timing, the error handling and the JSON of every endpoint
- **Guide tests** - each code block in the guides is a snippet in `test/snippets/`, and `test/guides/` asserts the exact results that the guides show
- **100% coverage** - For all code in `src/`; `gleam test` fails below it

See the [Testing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/testing.md) for details.

## Documentation Requirements

Update documentation for:
- New features (HexDocs + README)
- API changes (update all references)
- Breaking changes (migration guide)

Every code block in the README and in the HexDocs comes from a tested snippet in `test/snippets/`. See [Code Blocks in READMEs and Guides](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md#code-blocks-in-readmes-and-guides).

## Review Process

1. **Automated checks:**
   - Code formatting (`gleam format`)
   - Tests and 100% line coverage
   - Docs build
   - No compiler warnings

2. **Manual review:**
   - Code quality
   - Tests coverage
   - Documentation
   - Fits Dream's philosophy

3. **Maintainer approval:**
   - At least one maintainer approval required
   - May request changes or clarification

## Getting Help

- **Questions?** [Open a discussion](https://github.com/TrustBound/dream/discussions)
- **Stuck?** Comment on your PR or issue
- **Security issue?** See [SECURITY.md](SECURITY.md)

## Recognition

All contributors are recognized in our documentation and release notes. Thank you for making Dream better! 🎉

## About Dream

Dream was created by [TrustBound](https://trustbound.ai), an AI security platform, to build our production SaaS. We needed a type-safe web toolkit that was explicit, composable, and ran on the BEAM for massive concurrency.

We built Dream, used it to build TrustBound, and open-sourced it under MIT license so others could benefit.

Dream is community-driven. TrustBound funds development, but contributions come from everyone. All decisions happen in public issues and discussions.

---

**Read more:** [Full Contributing Guide](https://github.com/TrustBound/dream/blob/release/3.0.0/docs/contributing/contributing.md)
