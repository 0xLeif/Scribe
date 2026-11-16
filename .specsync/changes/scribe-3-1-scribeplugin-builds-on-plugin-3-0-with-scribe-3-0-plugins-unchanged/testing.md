---
change: scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged
artifact: testing
---

# Testing

- `swift test` in Swift 6 mode; the existing 15 tests still pass unchanged.
- New REQ-Scribe-5 tests: a struct and an actor written against 3.0 register and receive entries in order; a Scribe plugin used as a Plugin `ImmutablePlugin<Scribe.PluginPayload>`.
- `specsync check --strict`.
