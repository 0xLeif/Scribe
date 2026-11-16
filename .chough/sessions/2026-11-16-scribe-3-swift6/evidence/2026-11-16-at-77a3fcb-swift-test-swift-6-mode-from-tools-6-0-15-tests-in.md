---
kind: evidence
id: 2026-11-16-at-77a3fcb-swift-test-swift-6-mode-from-tools-6-0-15-tests-in
aliases: []
claim: "At 77a3fcb: swift test (Swift 6 mode from tools 6.0) 15 tests in 4 suites pass with no data-race diagnostics, including 1,000 entries in order, a throwing plugin not stopping delivery, a slow plugin not blocking 100 log calls (<500 ms), 50 tasks x 100 entries delivered exactly once in per-task order, and Package.swift listing only swift-log; specsync check --strict passes; the builder's release build, ThreadSanitizer run and DocC build pass"
result: passed
evidence_kind: product-test
method: swift test and specsync (orchestrator re-run); builder's swift build -c release, swift test --sanitize=thread and xcodebuild docbuild
revision: 77a3fcb515d1b78d697942148814e357acb76ec0
content: 4270d45686568b8a380dfa44b3ec0ea07f9e1a70888fee2124649c83ec00e101
environment: local-macos-arm64
criteria: [SWIFT6-1, SWIFT6-2, SWIFT6-3]
requirements: [REQ-Scribe-1, REQ-Scribe-2, REQ-Scribe-3, REQ-Scribe-4]
contracts: []
limitations:
  - "Apple platforms only (OSAllocatedUnfairLock: macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1); plugin errors are dropped with no hook; the pipeline buffer is unbounded; Package.resolved stays git-ignored"
observed: 2026-11-16T02:45:27Z
actor:
  - agent: claude-code
    terminal: t28
---
**At 77a3fcb: swift test (Swift 6 mode from tools 6.0) 15 tests in 4 suites pass with no data-race diagnostics, including 1,000 entries in order, a throwing plugin not stopping delivery, a slow plugin not blocking 100 log calls (<500 ms), 50 tasks x 100 entries delivered exactly once in per-task order, and Package.swift listing only swift-log; specsync check --strict passes; the builder's release build, ThreadSanitizer run and DocC build pass.**

Recorded as passed in local-macos-arm64 at revision 77a3fcb515d1, observed 2026-11-16T02:45:27Z.
