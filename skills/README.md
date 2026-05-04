# Health Forge — Agent Skills

Skills for AI coding agents (Claude Code, Cursor, Codex, OpenCode, and 50+ others) to integrate Health Forge packages into Flutter apps.

These skills follow the [Agent Skills](https://skills.sh) format, installable via the `npx skills` CLI.

## Install

Install all six skills into your project:

```bash
npx skills add mandarnilange/health_forge
```

Install a specific skill:

```bash
npx skills add mandarnilange/health_forge --skill integrate-health-forge-oura
```

List available skills without installing:

```bash
npx skills add mandarnilange/health_forge --list
```

Target a specific agent:

```bash
npx skills add mandarnilange/health_forge --agent claude-code
```

Install globally (user directory) instead of project:

```bash
npx skills add mandarnilange/health_forge --global
```

See the full CLI reference at <https://skills.sh/docs/cli>.

## Skills

| Skill | When to trigger |
|---|---|
| [`integrate-health-forge-core`](integrate-health-forge-core/SKILL.md) | User needs the unified health data model or merge engine without Flutter |
| [`integrate-health-forge`](integrate-health-forge/SKILL.md) | User is building a Flutter app that needs to aggregate health data from any provider |
| [`integrate-health-forge-apple`](integrate-health-forge-apple/SKILL.md) | User wants to read Apple HealthKit data on iOS |
| [`integrate-health-forge-ghc`](integrate-health-forge-ghc/SKILL.md) | User wants to read Google Health Connect data on Android |
| [`integrate-health-forge-oura`](integrate-health-forge-oura/SKILL.md) | User wants to read Oura Ring data via REST API |
| [`integrate-health-forge-strava`](integrate-health-forge-strava/SKILL.md) | User wants to read Strava activity data via REST API |

## Skill structure

Each skill folder contains:

- `SKILL.md` — frontmatter (name, description, license, metadata) plus the integration recipe.
- `metadata.json` — version, organization, abstract, references.

Each skill is self-contained: installation, platform setup, client wiring, and a minimal working snippet for the package it targets. Skills cross-reference each other where integration requires multiple packages (e.g. every adapter depends on `health_forge` + `health_forge_core`).

For multi-provider integrations, dispatch one agent per adapter skill in parallel — each skill is independent.

## Manual installation

If you can't use the CLI, copy any skill directory into your project's skills location:

```bash
# Claude Code (project-scoped)
cp -r skills/integrate-health-forge ~/your-project/.claude/skills/

# Claude Code (user-scoped)
cp -r skills/integrate-health-forge ~/.claude/skills/
```
