# Moving from 2.x

Update a Scribe 2.x project to Scribe 3.0.

## Overview

Scribe 3.0.0 builds in the Swift 6 language mode and no longer depends on the Plugin or Fork packages. Its only dependency is swift-log.

- Swift 6.0 (swift-tools-version 6.0) and macOS 13, iOS 16, tvOS 16, watchOS 9 or visionOS 1 are required.
- ``ScribePlugin`` is now Scribe's own protocol, `ScribePlugin: Sendable`, with `func handle(value: Scribe.PluginPayload) async throws`. Remove `import Plugin`, and make each plugin `Sendable`: an actor, a struct, or a final class with a lock.
- ``Scribe`` is a `final class` and `Sendable`, so it cannot be subclassed.
- ``Scribe/plugins`` is read-only. Use ``Scribe/register(plugin:)``, ``Scribe/remove(plugin:)`` and ``Scribe/removeAllPlugins()``.
- Logging calls no longer return a `Task`. Call ``Scribe/flush()`` to wait until plugins have received what was logged.
- Each plugin receives entries in the order they were logged, one at a time, and a plugin's error no longer ends delivery.
- ``Scribe/PluginPayload`` adds `file`, `function`, `line` and `date`.

A 2.x test that awaited the returned task:

```swift
try await scribe.debug("Test").value
```

becomes:

```swift
scribe.debug("Test")
await scribe.flush()
```
