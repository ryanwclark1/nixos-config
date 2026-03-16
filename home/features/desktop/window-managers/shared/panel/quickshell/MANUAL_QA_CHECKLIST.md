# Quickshell Manual QA Checklist

Use this after the automated checks are green. Focus on the cases the scripts explicitly leave uncovered.

## Settings Layout

- Open Settings Hub and verify the layout at wide desktop width.
- Resize to a laptop-sized width and verify tab content still fits without clipped controls.
- Resize to a narrow or portrait layout and verify:
  - the launcher tabs still open and scroll correctly
  - drag handles and reorder fallback arrows remain usable
  - long labels wrap instead of overlapping

## Bar Anchors

- Verify a top bar layout:
  - no clipped widgets
  - popups anchor correctly
  - notifications, control center, audio, and network surfaces open in expected positions
- Verify a bottom bar layout with the same checks.
- Verify a left bar layout with the same checks.
- Verify a right bar layout with the same checks.

## Multibar

- Configure at least two bars on different edges.
- Confirm each bar renders only its assigned widgets.
- Reorder widgets in one bar and confirm the other bar is unchanged.
- Open Bar Settings and Bar Widgets settings and confirm the selected bar state stays consistent.

## Launcher

- Open launcher in:
  - default app mode
  - files mode
  - web mode
  - launcher settings tabs
- Verify at wide, laptop, and narrow widths:
  - mode sidebar remains usable
  - result list selection is visible
  - web provider hints do not overlap
  - launcher home sections do not clip

## Runtime Sanity

- Trigger:
  - notifications
  - control center
  - AI chat
  - notepad
  - color picker
- Watch the user journal during interaction:

```bash
journalctl --user -f | rg 'quickshell|WARN|ERROR'
```

- Confirm no new warnings or errors appear during normal interaction.

## Recommended Interactive Commands

```bash
quickshell ipc call SettingsHub open
quickshell ipc call Shell openSurface controlCenter
quickshell ipc call Shell openSurface notifCenter
quickshell ipc call Launcher openDrun
quickshell ipc call Launcher openFiles
quickshell ipc call Launcher openWeb
```
