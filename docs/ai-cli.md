# AI CLI configuration ownership

Codex, Pi, Claude Code, agy and OpenCode use their native, writable user configuration. Nix installs
the programs and supplies integrations; it no longer generates shared instructions, agents or
commands. There is no replacement for the removed `modules/common/ai` rendering layer.

## Ownership

| Tool        | Native settings                                                                           | User instructions                                   |
| ----------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------- |
| Codex       | `~/.codex/config.toml`                                                                    | `~/.codex/AGENTS.md`                                |
| Pi          | `~/.pi/agent/settings.json`                                                               | `~/.pi/agent/AGENTS.md`                             |
| Claude Code | `~/.claude/settings.json`                                                                 | `~/.claude/CLAUDE.md`                               |
| agy         | `~/.gemini/antigravity-cli/settings.json`                                                 | `~/.gemini/AGENTS.md` or `GEMINI.md`, as configured |
| OpenCode    | `~/.config/opencode/opencode.json` or `opencode.jsonc`; `cli.json` (v2) / `tui.json` (v1) | `~/.config/opencode/AGENTS.md`                      |

These are the default paths. Respect `CODEX_HOME`, `PI_CODING_AGENT_DIR`, `CLAUDE_CONFIG_DIR` and
any configured Home Manager directory overrides. Codex also uses the XDG config directory when Home
Manager's `home.preferXdgDirectories` is enabled. OpenCode respects `XDG_CONFIG_HOME`.

Edit models, UI preferences, permissions, hooks and resource lists locally, or use the tool's own
settings commands. No rebuild is needed. Reload or restart the tool as required; Pi supports
`/settings` and `/reload`. Keep credentials and sessions outside this repository.

Nix still owns:

- Package installation and enable flags in `users/johnson/home/cli/ai/`.
- Shared MCP integration for Codex, Claude Code, agy and OpenCode via `my.mcp`. Pi's MCP setup is
  local.
- OpenCode's launcher reads the OpenRouter key from its SOPS file at runtime, not into the Nix
  store.
- Headroom routing for Claude Code when `my.headroom.enable` is true, and for Codex when
  `my.codex.useHeadroom` is true. Codex currently opts out in `users/johnson/home/default.nix`.
- Z-Library plugin installation when `my.zlib.enable` is true.

All five modules enable `mutableSettings`. For Codex, Pi, Claude Code and agy, **declared
integration values still win on activation**. Other local settings survive. A future Nix declaration
of a model or preference would make that value managed again. Managed plugins and generated MCP
resources may still be read-only; install other plugins/resources through each tool's native
workflow.

OpenCode instead loads a separate read-only `~/.config/opencode/home-manager.json` MCP layer through
`OPENCODE_CONFIG`. It does not merge Nix values into the writable user files. The layer overrides
global user settings for the same keys; project settings can override it. After activation, start a
new login session so `OPENCODE_CONFIG` reaches OpenCode. Launches outside that environment must also
receive the variable to use the managed MCP servers. With MCP disabled, no Nix layer is generated.

## Before the first switch

This change does not activate a generation or change existing files in your home directory. Stop the
AI tools before migration or activation to avoid concurrent writes.

1. Back up native configuration and any generated instructions/resources you want to keep. Keep the
   backup private and outside Git: settings can contain credentials. Back up file contents, not just
   links into the Nix store.
2. Detach old Home Manager settings symlinks before switching. Pi, Claude Code and OpenCode
   previously had immutable settings; without this step, a removed declaration can remove the old
   link. The following Bash example backs up and detaches a single file. Repeat for each settings
   file above that is a symlink, adjusting paths for directory overrides:

   ```bash
   set -euo pipefail
   file="$HOME/.pi/agent/settings.json"
   backup=$(mktemp -d "$HOME/.ai-config-backup.XXXXXXXX")
   chmod 700 "$backup"
   if [ -f "$file" ]; then
     cp -L "$file" "$backup/settings.json"
     chmod 600 "$backup/settings.json"
     if [ -L "$file" ]; then
       temporary=$(mktemp "${file}.XXXXXXXX")
       cp "$backup/settings.json" "$temporary"
       chmod 600 "$temporary"
       mv -f "$temporary" "$file"
     fi
   fi
   ```

   This deliberately preserves current settings, including Pi package registrations. It does not
   import a new defaults file or touch authentication/session files. Home Manager leaves the
   detached regular file in place when retiring the old symlink.

3. Review the preserved settings. Removing Nix declarations **does not erase values already in
   mutable files**. In particular:
   - Claude's old `hooks` refer to generated Nix-store scripts and an icon no longer installed.
     Remove those hook entries or replace them with maintained local scripts before garbage
     collection. Review the old `permissions` and status-line configuration too.
   - Codex retains previously merged feature flags, trusted projects, sandbox settings and its
     Nix-store `notify` command. Remove or replace the notification command. Decide which trust and
     permission settings to keep; simplification does not reset them to upstream defaults.
   - agy retains its old settings and permission lists until you edit them.
   - For OpenCode, also back up/detach `tui.json` and `oh-my-openagent.json` if you want to keep
     them. Review preserved models, plugins, permissions, LSP and formatter settings. Replace old
     Nix-store executable paths with locally maintained commands before garbage collection. Remove
     any `dotfiles-expert` default-agent reference. If using the Nix MCP layer, remove stale
     duplicate MCP entries from the native config after review. `opencode.jsonc` takes precedence
     over `opencode.json`; check both if present.
   - Disabling Headroom or removing an MCP/plugin declaration does not necessarily clear an existing
     mutable registration. Clean up the corresponding native entries explicitly.
4. Shared context, agents and commands, Codex profiles/rules, and Claude's WakaTime plugin are no
   longer installed by this configuration. Back up or detach individual generated files you want to
   maintain locally before activation. Otherwise let Home Manager retire its links. Existing
   user-created files are not intentionally deleted. Codex's automatic `~/Dev` trust wrapper and
   unconditional hook-trust bypass are gone; native trust checks apply.
5. Build and inspect before switching. Do not run `just test` as a build-only check: it activates.

OpenCode no longer declares models, default agents, commands, plugins, permissions, LSP, formatters,
provider catalogs or UI preferences. Automatic nixporn theming is disabled for OpenCode so local
theme changes stay effective. The Oh My OpenAgent configuration module is removed too; install and
configure it locally if desired. OpenCode uses its own defaults unless native settings override
them. Copilot and Hermes no longer receive shared context/agents/documents; their remaining
configuration is unchanged. On Hermes hosts, back up any generated documents you want to retain
before deployment.

## Validation

```bash
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/ai-cli.nix
nix --extra-experimental-features pipe-operators build --no-link \
  .#darwinConfigurations.eir.config.home-manager.users.johnson.home.activationPackage
```

The evaluation fixture checks Darwin and Linux ownership, disabled tools, and optional integrations.
It does not launch tools, modify native settings or activate a generation. See the
[deployment guide](src/content/docs/operations/deployment.md) for full host builds and activation.
