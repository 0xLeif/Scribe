# Scribe delta

## ADDED

### REQUIREMENT REQ-Scribe-5

Every type written for Scribe 3.0 that conforms to `ScribePlugin` by implementing only `func handle(value: Scribe.PluginPayload) async throws` SHALL compile and behave unchanged with Scribe 3.1, and Scribe 3.1 SHALL keep 3.0's public API (SWIFT6-4).

Acceptance Criteria:
- A struct and an actor written against Scribe 3.0's `ScribePlugin` register and receive every entry in order with Scribe 3.1.
- A Scribe 3.1 plugin can be used where Plugin 3.0 expects an `ImmutablePlugin` of `Scribe.PluginPayload`.

## MODIFIED

### REQUIREMENT REQ-Scribe-2

Scribe SHALL define `ScribePlugin` as a refinement of Plugin 3.0's `ImmutablePlugin` whose input is `Scribe.PluginPayload`, keeping the single requirement `func handle(value: Scribe.PluginPayload) async throws`, and SHALL depend only on swift-log and Plugin 3.x; the Fork package SHALL NOT be a dependency (SWIFT6-2, SWIFT6-4).

Acceptance Criteria:
- Package.swift lists only swift-log and Plugin (from 3.0.0) as dependencies.
- A plugin can be registered at creation and with `register(plugin:)`, and removed.

## REMOVED

(none)
