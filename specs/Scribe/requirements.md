---
spec: Scribe.spec.md
---

# Scribe requirements

### REQ-Scribe-1

Scribe SHALL build in the Swift 6 language mode with complete data-race checking (swift-tools-version 6.0), and `Scribe`, `ScribePlugin` and `Scribe.PluginPayload` SHALL be `Sendable` (SWIFT6-1).

Acceptance Criteria:
- `swift build` and `swift test` pass with swift-tools-version 6.0 and no data-race diagnostics.
- A `Scribe` can be shared between tasks and actors without unchecked conformances in the caller.

### REQ-Scribe-2

Scribe SHALL define its own plugin protocol, `ScribePlugin: Sendable` with `func handle(value: Scribe.PluginPayload) async throws`, and SHALL depend only on swift-log; the Plugin and Fork packages SHALL be removed (SWIFT6-2).

Acceptance Criteria:
- Package.swift lists only swift-log as a dependency.
- A plugin can be registered at creation and with `register(plugin:)`, and removed.

### REQ-Scribe-3

Each logging call (`trace` through `critical`, and `log(level:…)`) SHALL return without awaiting, SHALL log to swift-log, and SHALL hand the entry to every registered plugin; each plugin SHALL receive entries in the order they were logged, one at a time, and a plugin that throws SHALL NOT stop later entries or other plugins (SWIFT6-3).

Acceptance Criteria:
- Logging 1,000 entries from one task delivers them to a plugin in order.
- A plugin that throws on one entry still receives the next one, and other plugins receive every entry.
- A plugin that is slow does not block the caller.

### REQ-Scribe-4

Scribe 3.0.0 SHALL be released as a new major version, with the README and DocC describing the 3.0 API and how to move from 2.x (SWIFT6-1, SWIFT6-2).

Acceptance Criteria:
- The README shows creating a Scribe, writing and registering a plugin, and logging, in Swift 6.
- The README has a "Moving from 2.x" section.
