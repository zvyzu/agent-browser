# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

agent-browser is a headless browser automation CLI for AI agents. It provides a fast Rust CLI with Node.js fallback, using Playwright for browser control.

## Build Commands

```bash
pnpm install              # Install dependencies
pnpm build                # Build TypeScript to dist/
pnpm build:native         # Build Rust CLI (requires rustup.rs)
pnpm dev                  # Run daemon in dev mode with tsx
pnpm test                 # Run all tests with Vitest
pnpm test:watch           # Run tests in watch mode
pnpm typecheck            # TypeScript type checking (no emit)
pnpm format               # Format code with Prettier
pnpm format:check         # Check formatting
```

To run a single test file: `pnpm test src/actions.test.ts`

## Architecture

The project uses a **client-daemon architecture**:

```
┌─────────────────┐     Unix socket     ┌──────────────────┐     Playwright    ┌─────────┐
│   Rust CLI      │ ──── or TCP ─────▶ │  Node.js Daemon  │ ─────────────────▶ │ Browser │
│  (cli/src/*.rs) │      (JSON)         │   (src/*.ts)     │                    │         │
└─────────────────┘                     └──────────────────┘                    └─────────┘
```

1. **Rust CLI** (`cli/`) - Fast native binary that parses commands, communicates with daemon via socket
2. **Node.js Daemon** (`src/daemon.ts`) - Long-running process managing Playwright browser instance
3. **Fallback** - If native binary unavailable, uses Node.js directly via `bin/agent-browser`

The daemon starts automatically on first command and persists between commands.

## Key Source Files

### TypeScript Daemon (`src/`)
- `daemon.ts` - Socket server, session management, daemon lifecycle
- `browser.ts` - `BrowserManager` class wrapping Playwright (page/tab/context management, CDP, screencast)
- `actions.ts` - Command execution handlers (click, fill, navigate, etc.)
- `protocol.ts` - JSON command parsing with Zod schemas for validation
- `snapshot.ts` - Accessibility tree snapshot generation with ref system (@e1, @e2)
- `stream-server.ts` - WebSocket server for viewport streaming
- `types.ts` - TypeScript type definitions for commands/responses

### Rust CLI (`cli/src/`)
- `main.rs` - Entry point, argument handling, daemon spawning
- `commands.rs` - Command parsing, translates CLI args to JSON protocol
- `connection.rs` - Daemon connection via Unix socket (macOS/Linux) or TCP (Windows)
- `flags.rs` - CLI flag parsing (--json, --session, --headed, etc.)
- `output.rs` - Response formatting, help text, colored output
- `install.rs` - Chromium browser installation

## Protocol

Commands are sent as newline-delimited JSON over socket. Each command has:
- `id`: unique request ID
- `action`: command type (e.g., "navigate", "click", "snapshot")
- Additional fields per action (defined in `protocol.ts` schemas)

Responses return `{id, success, data?/error?}`.

## Ref System

The `snapshot` command returns an accessibility tree with refs like `@e1`, `@e2`. These refs can be used in subsequent commands (`click @e1`, `fill @e2 "text"`) to target elements without CSS selectors. The ref map is cached in `BrowserManager` and regenerated on each snapshot.

## Sessions

Multiple isolated browser instances via `--session <name>` flag or `AGENT_BROWSER_SESSION` env var. Each session has its own:
- Socket/port (based on session name hash)
- PID file (`/tmp/agent-browser-<session>.pid`)
- Browser instance with separate cookies/storage

## Windows Support

Uses TCP sockets on localhost instead of Unix sockets. Port derived from session name hash (range 49152-65535).
