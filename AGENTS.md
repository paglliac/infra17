# Repository Guidelines

## Project Structure

This repository manages services and networking on a Debian VPS with Ansible. Application source lives in the repositories listed in `group_vars/all/services.yml`.

- `site.yml` deploys services. `env.yml` updates service environment keys, `data.yml` imports SQLite databases, and `vpn.yml` and `direct.yml` configure networking.
- `group_vars/all/` holds shared defaults, the service registry, and VPN settings. When adding a service, choose a port that is free across `services` and `ports_taken`.
- `roles/` holds reusable tasks and Jinja2 templates for systemd, Caddy, VPN profiles, and routing.

## Build and Deployment Commands

Use Ansible Core 2.15+ with `ansible.posix` and `community.general`. For deployment, copy `inventory.example.yml` to `inventory.local.yml` and set the host, SSH user, and `base_domain`.

- `make help` lists targets.
- `make deploy S=budget` provisions one service. Omit `S` to deploy all services.
- `make app S=budget` updates the checkout and dependencies, runs the configured build when needed, and restarts the service when changes require it.
- `make env S=budget K=KEY` prompts for a value. `make data S=budget FROM=~/budget17/data` replaces the configured server databases after confirmation.
- `make vpn` configures VPN servers and generates client profiles. `make direct` applies direct-routing rules.

## Coding Style

Use two-space YAML indentation, descriptive English task names, `snake_case` variables, and fully qualified module names such as `ansible.builtin.template`. Indent Makefile recipes with tabs. Keep tasks safe to rerun and use `no_log: true` where task output could expose secrets.

## Validation

Run this command locally to check all five playbooks with the example inventory.

```sh
ansible-playbook -i inventory.example.yml --syntax-check site.yml env.yml data.yml vpn.yml direct.yml
```

Runtime validation comes from Ansible assertions and the HTTP health check for each service with `health` configured.

## Commits and Pull Requests

Write short, descriptive commit subjects. Recent history uses plain subjects and area prefixes such as `vpn:` and `service:`. In pull requests, name the affected services or roles, record validation results, and link related issues when available. Describe any manual deployment steps.

## Configuration

For a new service, register the public deploy key printed on the first run as a read-only key in its GitHub repository, then rerun the deployment.

Keep `inventory.local.yml`, service `.env` values, and generated `vpn-profiles/` out of Git. VPN profiles contain private keys.
