# storyblok-mcp-cwd

Use the **hosted Storyblok MCP server** with the Storyblok token of **the project directory you are working in**.

A tiny POSIX shell wrapper. It looks for the nearest `.env.hermes`, takes the Storyblok Personal Access Token from it, and connects to `https://mcp.labs.storyblok.com/mcp` through [`mcp-remote`](https://github.com/geelen/mcp-remote). Your MCP client starts it as an ordinary local (stdio) server.

You don't need to fork or patch Storyblok or your agent. All tools still come live from Storyblok, so new Storyblok features show up right away.

## Why

Agencies and freelancers often run one Storyblok space per client, each with its own token. Most MCP clients have one fixed `Authorization` header per server. That leaves you with three options:

- Switch the token by hand every time you change project.
- Define one MCP server per client. This loads duplicate tool sets into the context.
- Patch the agent so it loads per-server env files.

This wrapper picks the account from the directory you start your agent in:

```text
~/Projects/client-a/.env.hermes   -> STORYBLOK_PERSONAL_ACCESS_TOKEN=<token A>
~/Projects/client-b/.env.hermes   -> STORYBLOK_PERSONAL_ACCESS_TOKEN=<token B>

cd ~/Projects/client-a && hermes   # Storyblok tools talk to space A
cd ~/Projects/client-b && hermes   # Storyblok tools talk to space B
```

The agent never sees the token. It only lives in the wrapper process. So it can't end up in the agent's logs, error messages or model context.

## How it works

1. Your MCP client spawns `storyblok-mcp` as a stdio server. Stdio children inherit the session's working directory.
2. The wrapper walks up from that directory to `$HOME` (or `/`) and stops at the first `.env.hermes`. You can start in a subdirectory of a project.
3. It reads `STORYBLOK_PERSONAL_ACCESS_TOKEN` from that file. It parses the file and does **not** source or execute it.
4. It runs `npx mcp-remote@<pinned> https://mcp.labs.storyblok.com/mcp --header 'Authorization:${STORYBLOK_MCP_AUTH_HEADER}' --transport http-only`. The header is passed as an environment variable that `mcp-remote` expands itself. The token therefore never appears in the process list (`ps`).
5. `mcp-remote` bridges stdio ⇄ Streamable HTTP. Every tool, schema and update comes straight from Storyblok's hosted server.

**Fails closed.** The wrapper exits with a clear error and never falls back to another account when:

- there is no `.env.hermes`,
- the file is unreadable,
- the token is missing or empty.

The chosen file is logged to stderr, for example `storyblok-mcp: using /home/me/Projects/client-a/.env.hermes`. The token itself is never logged.

## Install

Requirements: `sh`, `sed`, and Node.js with `npx` on `PATH`.

```bash
git clone https://github.com/seppegadeyne/storyblok-mcp-cwd.git ~/Projects/storyblok-mcp-cwd
ln -s ~/Projects/storyblok-mcp-cwd/bin/storyblok-mcp ~/.local/bin/storyblok-mcp
```

Per project, add an ignored env file:

```bash
echo 'STORYBLOK_PERSONAL_ACCESS_TOKEN=your-token' > .env.hermes
echo '.env.hermes' >> .gitignore
chmod 600 .env.hermes
```

## Client configuration

### Hermes Agent (`~/.hermes/config.yaml`)

```yaml
mcp_servers:
  storyblok:
    command: /home/you/.local/bin/storyblok-mcp
    timeout: 180
    connect_timeout: 60
    sampling:
      enabled: false
```

Do **not** set `cwd`. The server must inherit the session directory. Hermes starts stdio servers in its configured working directory: `terminal.cwd` / `TERMINAL_CWD`, otherwise the directory you launched from. With the default `terminal.cwd: .` that is the project you start `hermes` in. A `TERMINAL_CWD` exported from a parent Hermes session overrides it.

### Claude Code / Cursor / other stdio clients

```json
{
  "mcpServers": {
    "storyblok": { "command": "/home/you/.local/bin/storyblok-mcp" }
  }
}
```

This works in any client that starts stdio servers in the project directory.

## Configuration

All settings are optional environment variables, set in the MCP server's `env`:

| Variable | Default | Purpose |
|---|---|---|
| `STORYBLOK_MCP_ENV_FILE` | `.env.hermes` | File name to search for. An absolute path pins one file. |
| `STORYBLOK_MCP_TOKEN_KEY` | `STORYBLOK_PERSONAL_ACCESS_TOKEN` | Variable name inside the file |
| `STORYBLOK_MCP_URL` | `https://mcp.labs.storyblok.com/mcp` | Hosted endpoint |
| `STORYBLOK_MCP_REMOTE` | `mcp-remote@0.1.38` | npm spec of the bridge. It is pinned, so bump it on purpose. |

Supported env file syntax: `KEY=value`, `export KEY=value`, single or double quotes, and CRLF line endings. If the key appears more than once, the last assignment wins.

## Caveats

- **The directory counts when the server starts.** If you `cd` into another project inside a running session, the old account stays connected until the MCP server restarts (for example when you restart the agent or reload MCP). This is deliberate: a live connection never switches account silently.
- **Long-lived gateways, cron jobs and servers** have no meaningful project directory. There, hard-code the token in the profile/server config instead, or set `STORYBLOK_MCP_ENV_FILE` to an absolute path.
- There is one extra lightweight Node process per active connection.
- The first run downloads `mcp-remote` through `npx`. After that it comes from the npm cache.

## Background

This wrapper replaces a proposed core change to Hermes Agent ([NousResearch/hermes-agent#74809](https://github.com/NousResearch/hermes-agent/pull/74809)). That change added per-server `env_file` support. Handling credentials inside the agent turned out to need redaction across logs, probes, reconnects and error paths. Keeping the token outside the agent process avoids all of that.

## Tests

```bash
sh tests/parse.sh
```

This checks the env-file parser: `export`, quotes, CRLF, last-wins, and ignores comments and look-alike keys.

## License

MIT
