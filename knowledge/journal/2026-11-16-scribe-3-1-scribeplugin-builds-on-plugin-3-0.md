---
id: 2026-11-16-scribe-3-1-scribeplugin-builds-on-plugin-3-0
title: "Scribe 3.1: ScribePlugin builds on Plugin 3.0"
type: journal
tags: [chough/journal, chough/shipped]
date: 2026-11-16
time: 2026-11-16T03:32:10Z
kind: shipped
links:
  - .chough/archive/sessions/2026-11-16-scribe-3-1-plugin.md
  - .specsync/archive/changes/2026-11-16-scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged/
record: .chough/archive/sessions/2026-11-16-scribe-3-1-plugin.md
actor:
  - agent: claude-code
    terminal: t28
---
# Scribe 3.1: ScribePlugin builds on Plugin 3.0

Scribe 3.1: ScribePlugin builds on Plugin 3.0, with Scribe 3.0 plugins unchanged

Why: 0xLeif decided "Approve the scope of scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged": "yes do Plugin 3.0 and Scribe 3.1" (Claude Code chat (hc t28), 2026-11-16, approving Plugin 3.0 and Scribe 3.1 adopting it with Scribe 3.0 plugins unchanged); recorded by claude-code (hc t28); a relayed claim, not authenticated; ran specsync change approve scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged as 0xLeif

Verified: At c643310: swift test 21 tests in 6 suites pass (Swift 6, no data-race diagnostics), including 3.0-style struct and actor plugins in a target that doesn't import Plugin receiving 500 entries in order, and Scribe plugins registered one at a time into Plugin's Plugins and run with handleInOrder; specsync check --strict passes; the DocC archive…

Read more: [the story](../../.chough/archive/sessions/2026-11-16-scribe-3-1-plugin.md) · [the archived change](../../.specsync/archive/changes/2026-11-16-scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged/)
