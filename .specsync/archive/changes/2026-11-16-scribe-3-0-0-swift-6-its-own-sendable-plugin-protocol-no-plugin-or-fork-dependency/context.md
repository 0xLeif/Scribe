---
change: scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency
artifact: context
---

# Context

Leif chose Scribe as Starling's logger (2026-11-16) and asked to update it to Swift 6 under Chough. Scribe 2.0.2 (2023) depends on 0xLeif/Plugin, which depends on 0xLeif/Fork; Fork fails Swift 6 data-race checks (`ForkedActor.swift`), and Scribe's `open class Scribe` holds a mutable `plugins` array and is not Sendable. Leif approved dropping the Plugin and Fork dependency for a 3.0.0 major version ("yes i approve"). Starling's debug mode will use Scribe 3.0.0.
