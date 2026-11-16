---
change: scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency
artifact: testing
---

# Testing

- `swift build` and `swift test` in Swift 6 mode with no data-race diagnostics.
- Tests named with REQ-Scribe IDs: ordered delivery of 1,000 entries; a throwing plugin does not stop later entries or other plugins; register and remove; logging does not wait for a slow plugin.
- `specsync check --strict`.
