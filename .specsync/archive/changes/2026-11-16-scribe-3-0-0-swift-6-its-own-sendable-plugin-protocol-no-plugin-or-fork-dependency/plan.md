---
change: scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency
artifact: plan
---

# Plan

## Approach

`Package.swift`: swift-tools-version 6.0, swift-log only, platforms raised as Swift 6 concurrency needs (iOS 16, macOS 13 or whatever the code requires). `ScribePlugin: Sendable` with an async `handle(value:)`. `Scribe` becomes a `final class: Sendable` that keeps its plugins in a lock-protected list and feeds each entry, in order, through one `AsyncStream` consumed by a single task that calls each plugin in turn and ignores a plugin's error. `PluginPayload` is Sendable (swift-log's Level, Message and Metadata are Sendable). Tests move to Swift Testing.

## Out of scope

Updating the Plugin and Fork packages; new log outputs.

## Steps

1. Package and types.
2. Ordered delivery and plugin registration.
3. Swift Testing suite.
4. README, DocC and the spec's Public API.

## Risks

API break for 2.x users (major version); delivery is asynchronous, so a test must await it.

## Constraints consulted

Swift 6 strict concurrency; Starling's need for synchronous logging calls.
