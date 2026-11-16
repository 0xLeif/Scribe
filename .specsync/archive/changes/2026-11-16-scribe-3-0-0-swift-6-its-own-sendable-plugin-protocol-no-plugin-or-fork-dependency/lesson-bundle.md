# Lesson bundle: scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Scribe 3.0.0: Swift 6, its own Sendable plugin protocol, no Plugin or Fork dependency
- **Kind**: Feature
- **Specs**: Scribe
- **Paths**: Sources/Scribe, Tests/ScribeTests, Package.swift, Package.resolved, README.md, specs/Scribe, .chough/sessions, .specsync/sdd.json
- **Acceptance**: Scribe 3.0.0 builds in Swift 6 with Sendable public types, its own plugin protocol and only swift-log, logs synchronously and delivers every entry to each plugin in order.

## Evidence

- Verification commit: `f00b56fb399f4415d9a4357dbe581a41e280d875`
- Base commit: `6cb66280af3ae57fc1619ec1e3a89726ace89e8d`
- Verified by: `specsync check --spec Scribe`

## From the change's context.md

# Context

Leif chose Scribe as Starling's logger (2026-11-16) and asked to update it to Swift 6 under Chough. Scribe 2.0.2 (2023) depends on 0xLeif/Plugin, which depends on 0xLeif/Fork; Fork fails Swift 6 data-race checks (`ForkedActor.swift`), and Scribe's `open class Scribe` holds a mutable `plugins` array and is not Sendable. Leif approved dropping the Plugin and Fork dependency for a 3.0.0 major version ("yes i approve"). Starling's debug mode will use Scribe 3.0.0.

## From the change's design.md

# Design

No visual design: a library API.

## From the change's testing.md

# Testing

- `swift build` and `swift test` in Swift 6 mode with no data-race diagnostics.
- Tests named with REQ-Scribe IDs: ordered delivery of 1,000 entries; a throwing plugin does not stop later entries or other plugins; register and remove; logging does not wait for a slow plugin.
- `specsync check --strict`.

## Where these lessons go

- `specs/Scribe/context.md`
