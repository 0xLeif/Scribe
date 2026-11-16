# ``Scribe``

Log to swift-log and hand every entry, in order, to Sendable plugins.

## Overview

A ``Scribe`` writes each entry to swift-log and puts it on one ordered delivery pipeline. Logging calls are synchronous and never wait for a plugin. A single delivery task hands each entry to each ``ScribePlugin``, in the order the entries were logged, one at a time. A plugin that throws still receives later entries, and other plugins are not affected.

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
