---
change: scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency
artifact: research
---

# Research

- Building Scribe 2.0.2 with `-swift-version 6` fails in its dependency Fork (`ForkedActor.swift:57`, sending 'value' risks causing data races); a Swift 6 package keeps each dependency's own language mode, but Scribe's public API exposes Plugin's non-Sendable protocols.
- swift-log's `Logger`, `Logger.Level`, `Logger.Message` and `Logger.Metadata` are Sendable, so `PluginPayload` can be Sendable without wrappers.
- Ordered asynchronous delivery fits an `AsyncStream` with one consuming task; registration needs a lock (`Mutex` from Synchronization needs iOS 18 / macOS 15, so an `OSAllocatedUnfairLock` or `NSLock` keeps older platforms).
