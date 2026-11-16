---
hi: 1
families: [SWIFT6]
---

# Swift6

## Intent

Leif, 2026-11-16, in Claude Code chat, choosing Scribe as Starling's logger: "yes use Scribe, set it up.. also update scribe to be swift 6 and use chough"; then approving Scribe 3.0.0 that drops the Plugin and Fork dependency: "yes i approve". Later, after Plugin 3.0 was planned: "could we update plugin to be swift 6 and kept it in scribe?", then "yes do Plugin 3.0 and Scribe 3.1".

<!-- What is this for, and what should it feel like? Write it as a person. -->

## Criteria

- **SWIFT6-1**  Scribe builds in the Swift 6 language mode with complete data-race checking, and its public types are safe to share across threads
- **SWIFT6-2**  Scribe has its own plugin protocol and no longer depends on the Plugin or Fork packages; swift-log stays
- **SWIFT6-3**  Logging stays synchronous at the call site, and each plugin receives every entry in the order it was logged
- **SWIFT6-4**  Scribe uses Plugin 3.0 again: ScribePlugin builds on Plugin's immutable plugin protocol, and every Scribe 3.0 plugin keeps working unchanged
