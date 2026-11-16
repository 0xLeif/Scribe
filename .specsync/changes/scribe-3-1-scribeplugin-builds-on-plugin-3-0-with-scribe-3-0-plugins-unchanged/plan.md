---
change: scribe-3-1-scribeplugin-builds-on-plugin-3-0-with-scribe-3-0-plugins-unchanged
artifact: plan
---

# Plan

## Approach

Add Plugin from 3.0.0. `ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload` with no new requirements. Keep Scribe's own ordered delivery and error-skipping (Plugin's `handleInOrder` throws on the first error, which Scribe must not do), so Scribe keeps its plugin list; optionally store plugins in a `Plugins<Payload, Void>` if it keeps the behavior. Keep every 3.0 public API.

## Out of scope

Changing delivery or error semantics.

## Steps

1. Package and protocol.
2. Tests for 3.0 plugins unchanged and interop with Plugin.
3. README, DocC, spec; release 3.1.0.

## Risks

The Swift 6.4 existential conversion crash; avoided by registering one at a time.

## Constraints consulted

Source compatibility with Scribe 3.0; Swift 6.
