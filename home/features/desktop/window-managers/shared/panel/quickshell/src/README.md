# QuickShell panel `src/` layout

High-level map of the runtime tree. See [../ARCHITECTURE.md](../ARCHITECTURE.md) for dependency rules and invariants.

| Path | Role |
|------|------|
| `shell.qml` | Entry: loads `app/ShellRoot.qml`. |
| `app/` | Surface orchestration, IPC, per-screen wiring (`ShellRoot.qml`). |
| `shell/` | Shell-only decoration layers (not feature-owned). |
| `bar/` | Primary panel (`Panel.qml`), bar widgets, `components/`. |
| `features/` | Feature-owned surfaces, menus, and local components. |
| `shared/` | Reusable controls and layout helpers (`ScrollableContent`, `Scrollbar`, etc.). |
| `services/` | Singletons, config, compositor integration; must not import `features/`. |
| `launcher/` | Launcher / overview implementation. |
| `widgets/` | Compatibility re-exports; prefer `shared/` or `features/` for new code. |
