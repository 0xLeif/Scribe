# ``Scribe``

Log to swift-log and hand every entry, in order, to Sendable plugins.

## Overview

A ``Scribe`` writes each entry to swift-log and puts it on one ordered delivery pipeline. Logging calls are synchronous and never wait for a plugin. A single delivery task hands each entry to each ``ScribePlugin``, in the order the entries were logged, one at a time. A plugin that throws still receives later entries, and other plugins are not affected.

``ScribePlugin`` refines Plugin 3.0's `ImmutablePlugin` with its input fixed to ``Scribe/PluginPayload``, and keeps its single requirement, `handle(value:)`. Plugins written for Scribe 3.0 work unchanged in 3.1, and a Scribe plugin can also be registered in Plugin's `Plugins<Scribe.PluginPayload, Void>` (import Plugin; Scribe does not re-export it).

```swift
actor CountPlugin: ScribePlugin {
    private(set) var count = 0

    func handle(value: Scribe.PluginPayload) async throws {
        count += 1
    }
}

let counter = CountPlugin()
let scribe = Scribe(label: "com.example.app", plugins: [counter])

scribe.info("Signed in")
await scribe.flush()
```

## Topics

### Essentials

- ``Scribe``
- ``ScribePlugin``
- ``Scribe/PluginPayload``

### Articles

- <doc:MovingFrom2x>
