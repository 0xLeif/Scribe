# Scribe

*📜 Logging all events*

Scribe is a flexible logging library for Swift, designed to make logging easy and efficient. It provides a centralized system for logging messages and events within your application, and supports multiple logging outputs and plugins to extend its capabilities to meet your needs. Scribe integrates with [swift-log](https://github.com/apple/swift-log) for console logging, making it a versatile solution for all your logging requirements.

## Usage

### Creating a ScribePlugin

To create a Scribe plugin, you need to create a struct or class that conforms to the ScribePlugin protocol and implement its requirements. Here is an example of a simple plugin that increments a count for each log:

```swift
class CountPlugin: ScribePlugin {
    static let shared = CountPlugin()

    var count: Int = 0

    private init() {}

    func handle(value: Scribe.PluginPayload) async throws {
        count += 1
    }
}
```

### Registering plugins to Scribe

Once you have created your Scribe Plugin, you just need to register it with your Scribe object. There are two ways to do this:

1. Pass the plugin to the plugins parameter when creating the Scribe object:

```swift
let scribe = Scribe(
    label: "test.count",
    plugins: [
        CountPlugin.shared
    ]
)
```
        
2. Call `scribe.register(plugin:)` to add the plugin to an existing Scribe object:

```swift
let scribe = Scribe(label: "test.count")

scribe.register(plugin: CountPlugin.shared)
```

### Logging to Scribe

Scribe uses swift-log for logging, so the functions are similar in usage. To log a message with Scribe, simply call one of the logging functions, such as debug:

```swift
scribe.debug("Test")
```

#### Log Levels

Scribe supports the following log levels:

- `trace`
- `debug`
- `info`
- `notice`
- `warning`
- `error`
- `critical`

Choose the appropriate log level depending on the importance and urgency of the message you are logging.
