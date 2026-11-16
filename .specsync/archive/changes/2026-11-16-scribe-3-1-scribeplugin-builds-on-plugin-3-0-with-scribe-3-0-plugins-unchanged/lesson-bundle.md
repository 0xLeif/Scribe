# Lesson bundle: scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Scribe 3.1: ScribePlugin builds on Plugin 3.0, with Scribe 3.0 plugins unchanged
- **Kind**: Feature
- **Specs**: Scribe
- **Paths**: Sources/Scribe, Tests/ScribeTests, Package.swift, README.md, specs/Scribe, .chough/sessions, hi/swift6.md, INTENT.md
- **Acceptance**: Scribe 3.1 depends on Plugin 3.0, ScribePlugin refines ImmutablePlugin, and every Scribe 3.0 plugin and API keeps working unchanged.

## Evidence

- Verification commit: `e4bf6f532159068c5a630968c63851eb3213e7f1`
- Base commit: `375c663dfbfac31ab3777ab908b81dbfddcc9099`
- Verified by: `specsync check --spec Scribe`

## From the change's context.md

# Context

Plugin 3.0.0 (released 2026-11-16, 0xLeif/Plugin) is Swift 6 with `ImmutablePlugin<Input>: Plugin where Output == Void`. Leif asked for Scribe 3.1 to use it again ("yes do Plugin 3.0 and Scribe 3.1"). Plugin's tests show a ScribePlugin-shaped refinement works and that types written only against `handle(value:)` conform unchanged. Swift 6.4's type checker crashes converting `any ScribePlugin` to `any ImmutablePlugin<Payload>`; Plugin's `register(_:)` is generic so `register(anyScribePlugin)` works, but `register(contentsOf: [any ScribePlugin])` does not, so Scribe registers one at a time.

## From the change's design.md

# design

No visual design. Plugin 3.0.0's README and tests document the refinement and the Swift 6.4 existential crash.

## From the change's testing.md

# Testing

- `swift test` in Swift 6 mode; the existing 15 tests still pass unchanged.
- New REQ-Scribe-5 tests: a struct and an actor written against 3.0 register and receive entries in order; a Scribe plugin used as a Plugin `ImmutablePlugin<Scribe.PluginPayload>`.
- `specsync check --strict`.

## Where these lessons go

- `specs/Scribe/context.md`
