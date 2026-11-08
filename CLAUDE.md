# Agent guidance

Follow [AGENTS.md](AGENTS.md) for repository rules, layout, validation and change safety. Do not
maintain a separate copy of those instructions here.

Before changing configuration, read [docs/README.md](docs/README.md) and the relevant guide:

- [Deployment and checks](docs/src/content/docs/operations/deployment.md)
- [Network ownership and rollback gates](docs/networking.md)
- [SSH configuration](docs/SSH_CONFIG.md)
- [SOPS and bootstrap](docs/SOPS.md)

Use `just --list` and the [justfile](justfile) as the command reference. `just test` activates a
temporary system generation; it is not a build-only check. For a build without activation, use the
platform-specific commands in the deployment guide.
