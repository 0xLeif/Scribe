---
change: scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged
artifact: context
---

# Context

Plugin 3.0.0 (released 2026-11-16, 0xLeif/Plugin) is Swift 6 with `ImmutablePlugin<Input>: Plugin where Output == Void`. Leif asked for Scribe 3.1 to use it again ("yes do Plugin 3.0 and Scribe 3.1"). Plugin's tests show a ScribePlugin-shaped refinement works and that types written only against `handle(value:)` conform unchanged. Swift 6.4's type checker crashes converting `any ScribePlugin` to `any ImmutablePlugin<Payload>`; Plugin's `register(_:)` is generic so `register(anyScribePlugin)` works, but `register(contentsOf: [any ScribePlugin])` does not, so Scribe registers one at a time.
