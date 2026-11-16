---
module: Scribe
version: 2
status: active
files:
  - Sources/Scribe/Scribe.swift
  - Sources/Scribe/ScribePlugin.swift

db_tables: []
depends_on: []
---

# Scribe

## Purpose

Scribe is a Swift 6 logging library. A `Scribe` writes each entry to swift-log and hands it to every registered `ScribePlugin`, in the order entries were logged, one at a time, without making the caller wait. It owns the plugin list, the ordered delivery pipeline and the plugin payload; it does not own any log output beyond swift-log, which the caller configures (REQ-Scribe-1, REQ-Scribe-2, REQ-Scribe-3).

## Public API

| Export | Description |
|--------|-------------|
| `Scribe` | `public final class Scribe: Sendable`. Wraps a swift-log `Logger` and a lock-protected plugin list; safe to share between tasks and actors. |
| `init` | `init(label:plugins:)`, `init(label:factory:plugins:)` and `init(label:metadataProvider:plugins:)` create the swift-log `Logger` the same way swift-log does and register the given plugins in order. `PluginPayload.init` builds a payload; its `file`, `function`, `line` and `date` default to the call site and now. |
| `Level` | Alias for swift-log's `Logger.Level`. |
| `Message` | Alias for swift-log's `Logger.Message`. |
| `Metadata` | Alias for swift-log's `Logger.Metadata`. |
| `PluginPayload` | `Sendable` struct handed to each plugin for one logged entry. |
| `level` | The entry's log level. |
| `message` | The entry's message. |
| `metadata` | The metadata passed to the log call, or `nil`. |
| `source` | The source passed to the log call, or `nil`. |
| `file` | The `#fileID` of the log call. |
| `function` | The `#function` of the log call. |
| `line` | The `#line` of the log call. |
| `date` | When the log call was made. |
| `PluginRegistration` | `Hashable`, `Sendable` token returned by `register(plugin:)`; identifies one registration for `remove(plugin:)`. |
| `plugins` | Read-only snapshot of the registered plugins, in registration order. |
| `register` | `register(plugin:)` adds a plugin, which receives every entry logged after the call; returns a `PluginRegistration` (discardable). |
| `remove` | `remove(plugin:)` removes one registration; that plugin receives no entry logged after the call. |
| `removeAllPlugins` | Removes every plugin, including those registered at creation. |
| `flush` | `flush() async` returns once every entry logged before the call has been handed to its plugins. |
| `log` | `log(level:_:metadata:source:file:function:line:)` logs to swift-log synchronously and enqueues the entry for the plugins registered at that moment; returns `Void` without awaiting. |
| `trace` | Logs at `.trace`; same parameters and behavior as `log`. |
| `debug` | Logs at `.debug`; same parameters and behavior as `log`. |
| `info` | Logs at `.info`; same parameters and behavior as `log`. |
| `notice` | Logs at `.notice`; same parameters and behavior as `log`. |
| `warning` | Logs at `.warning`; same parameters and behavior as `log`. |
| `error` | Logs at `.error`; same parameters and behavior as `log`. |
| `critical` | Logs at `.critical`; same parameters and behavior as `log`. |
| `ScribePlugin` | `public protocol ScribePlugin: Sendable` with `func handle(value: Scribe.PluginPayload) async throws`. |
| `handle` | Called once per entry per plugin, on Scribe's delivery task. |

### Types

| Type | Kind | Description |
|------|------|-------------|
| `Scribe` | final class, `Sendable` | The logger and plugin host. |
| `Scribe.PluginPayload` | struct, `Sendable` | One logged entry: level, message, metadata, source, file, function, line, date. |
| `Scribe.PluginRegistration` | struct, `Hashable`, `Sendable` | Token for removing one registered plugin. |

### Protocols

| Protocol | Description |
|----------|-------------|
| `ScribePlugin` | `Sendable` receiver of logged entries; `handle(value:)` is `async throws`. |

## Invariants

1. The package builds with swift-tools-version 6.0 (Swift 6 language mode) and depends only on swift-log (REQ-Scribe-1, REQ-Scribe-2).
2. `Scribe`, `Scribe.PluginPayload`, `Scribe.PluginRegistration` and `ScribePlugin` are `Sendable` with checked conformances; the plugin list is guarded by `OSAllocatedUnfairLock`, with no `@unchecked Sendable` (REQ-Scribe-1).
3. A logging call never awaits: it logs to swift-log, then enqueues the entry under the plugin lock, so pipeline order equals the order calls took the lock (REQ-Scribe-3).
4. One delivery task consumes the pipeline; it hands each entry to each plugin in registration order and waits for each `handle` before the next, so a plugin receives entries one at a time in logged order (REQ-Scribe-3).
5. An entry goes to the plugins registered when it was logged; a plugin registered later or removed earlier does not receive it.
6. Entries already logged are still delivered after the `Scribe` is released; the delivery task holds the stream, not the `Scribe`.

## Behavioral Examples

### Scenario: Ordered delivery

- **Given** a Scribe with one plugin
- **When** one task logs 1,000 entries and then awaits `flush()`
- **Then** the plugin has received all 1,000 entries in the order they were logged

### Scenario: Throwing plugin

- **Given** a Scribe with a plugin that throws on some entries, and a second plugin
- **When** five entries are logged and `flush()` is awaited
- **Then** the throwing plugin received all five, and the second plugin received all five

### Scenario: Slow plugin

- **Given** a plugin whose `handle` is blocked
- **When** 100 entries are logged
- **Then** every log call returns while the plugin is still blocked, and after it is unblocked `flush()` shows all 100 delivered

### Scenario: Register and remove

- **Given** a Scribe with a plugin registered at creation and one registered with `register(plugin:)`
- **When** `remove(plugin:)` or `removeAllPlugins()` is called between two log calls
- **Then** removed plugins receive only the first entry

### Scenario: Concurrent logging

- **Given** 50 tasks sharing one Scribe
- **When** each logs 100 entries
- **Then** the plugin receives each of the 5,000 entries exactly once, each task's entries in order

## Error Cases

| Condition | Behavior |
|-----------|----------|
| A plugin's `handle` throws | The error is discarded; that plugin still receives later entries and the remaining plugins receive this one. |
| No plugins are registered | The entry is logged to swift-log and not enqueued. |
| `flush()` after the pipeline has ended | Returns immediately. |
| A plugin never returns from `handle` | Later deliveries and `flush()` wait for it; logging calls still return immediately. The pipeline buffer is unbounded. |

## Dependencies

### Consumes

| Module | What is used |
|--------|-------------|
| swift-log (`Logging`) | `Logger`, `Logger.Level`, `Logger.Message`, `Logger.Metadata`, `Logger.MetadataProvider`, `LogHandler` |
| `os` | `OSAllocatedUnfairLock` for the plugin list |
| Foundation | `Date` in `PluginPayload` |

### Consumed By

| Module | What is used |
|--------|-------------|
| Starling (app) | `Scribe` and `ScribePlugin` for its log and debug log |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-11-16 | claude-code | Scribe 3.0.0: Swift 6, own `Sendable` `ScribePlugin`, swift-log only, ordered delivery pipeline with `flush()`, plugin removal, call site and date in `PluginPayload` (REQ-Scribe-1 to REQ-Scribe-4). |
| 2026-11-16 | SpecSync | scribe-3-0-0-swift-6-its-own-sendable-plugin-protocol-no-plugin-or-fork-dependency: Scribe 3.0.0: Swift 6, its own Sendable plugin protocol, no Plugin or Fork dependency |
