# Health Forge — AI Assistant Skills

Skills for coding agents (Claude Code, Cursor, Copilot, etc.) to integrate Health Forge packages into user Flutter apps.

Each skill is self-contained: installation, platform setup, client wiring, and a minimal working snippet for the package it targets. Skills cross-reference each other where integration requires multiple packages (e.g. every adapter depends on `health_forge` + `health_forge_core`).

## Skills

| Skill | When to trigger |
|---|---|
| [`integrate-health-forge-core`](integrate-health-forge-core/SKILL.md) | User needs the unified health data model or merge engine without Flutter |
| [`integrate-health-forge`](integrate-health-forge/SKILL.md) | User is building a Flutter app that needs to aggregate health data from any provider |
| [`integrate-health-forge-apple`](integrate-health-forge-apple/SKILL.md) | User wants to read Apple HealthKit data on iOS |
| [`integrate-health-forge-ghc`](integrate-health-forge-ghc/SKILL.md) | User wants to read Google Health Connect data on Android |
| [`integrate-health-forge-oura`](integrate-health-forge-oura/SKILL.md) | User wants to read Oura Ring data via REST API |
| [`integrate-health-forge-strava`](integrate-health-forge-strava/SKILL.md) | User wants to read Strava activity data via REST API |

## Usage

Copy a skill directory into your project's skills location (e.g. `.claude/skills/` for Claude Code), or point your agent harness at this directory. The `SKILL.md` frontmatter describes the trigger conditions; the body is the integration recipe.

For multi-provider integrations, dispatch one agent per adapter skill in parallel — each skill is independent.
