# Agent Desk Development Platform

## Platform Shape

This workstation is a multi-agent development environment for software engineering across repositories and languages.

Primary goals:

- Reliable project work in Python, TypeScript, Go, Rust, Nix, and other stacks
- Reproducible workstation and tool configuration
- Git-native task memory and workflow state
- Multi-agent software engineering workflows
- Local-first operation with cloud model support
- Shared skills, prompts, and procedures across agents

## Core Stack

- Beads is the persistent work ledger, memory layer, task graph, and dependency graph.
- Gastown is the orchestration layer for agent teams, workflows, messaging, patrols, and reviews.
- WorkMux creates isolated workspaces using git worktrees and terminal sessions.
- GitButler manages virtual branches, stacked branches, and agent-friendly changesets.
- Claude Code, Codex, OpenCode, and Antigravity are execution agents.
- Shared skills live under `AGENT_DESK_SKILLS_DIR`.
- Model proxy tooling should use OpenAI-compatible APIs where practical.
- NixOS and Home Manager provide the workstation/tooling substrate, but individual project conventions take precedence inside application repositories.

## Workflow

1. Create or identify a Beads work item.
2. Let Gastown or the human operator choose the workflow stage.
3. Use WorkMux for isolated implementation or research workspaces.
4. Keep changes scoped to one work item or one workflow stage.
5. Use GitButler for parallel and stacked changesets.
6. Review, test, document, then close the Beads item.

## Agent Roles

Research:
- Investigate options, constraints, prior art, and risks.
- Produce concise findings and cite sources where needed.

Architect:
- Turn research into design.
- Define interfaces, sequencing, tradeoffs, and ADRs.

Implementer:
- Make scoped, testable changes.
- Preserve existing repo conventions and minimize unrelated churn.
- Choose verification commands from the project stack: for example `pytest`, `ruff`, `mypy`, `npm test`, `pnpm test`, `tsc`, `go test`, `cargo test`, `cargo clippy`, or Nix evaluations as appropriate.

Reviewer:
- Look first for bugs, regressions, missing tests, and maintainability risks.
- Prefer concrete file and line references.

Documentation:
- Update architecture notes, runbooks, onboarding notes, and workflow docs.

## Operating Rules

- Prefer the repo's existing module boundaries and helpers.
- Detect the project stack before acting; do not assume a Nix project unless the files or request indicate it.
- Keep secrets out of plaintext configuration and generated artifacts.
- Use Beads/Gastown/WorkMux/GitButler as complementary layers, not replacements for each other.
- Use shared skills before copying prompts between agents.
- Prefer explicit verification commands and record failures honestly.
- For Nix workstation changes, evaluate the affected Home Manager or NixOS targets before calling the work done.
- For application changes, run the repository's own tests, type checks, linters, formatters, or build commands before calling the work done.
