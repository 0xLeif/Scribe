---
kind: evidence
id: 2026-11-16-at-c643310-swift-test-21-tests-in-6-suites-pass-swift-6-no
aliases: []
claim: "At c643310: swift test 21 tests in 6 suites pass (Swift 6, no data-race diagnostics), including 3.0-style struct and actor plugins in a target that doesn't import Plugin receiving 500 entries in order, and Scribe plugins registered one at a time into Plugin's Plugins and run with handleInOrder; specsync check --strict passes; the DocC archive built with --hosting-base-path Scribe references /Scribe/js"
result: passed
evidence_kind: product-test
method: swift test, specsync and a local docbuild plus transform-for-static-hosting (orchestrator); builder's sanitizer, release build and MemberImportVisibility consumer check
revision: c64331009b6bed264d3db8614ffc6951257fdb5f
content: ea74425097b99e213d6eb9675dd4f3921846b2db0969aa68341cd658bc4803e2
environment: local-macos-arm64
criteria: [SWIFT6-4]
requirements: [REQ-Scribe-2, REQ-Scribe-5]
contracts: []
limitations: [The live Pages site updates only after the docc workflow runs on main]
observed: 2026-11-16T03:29:20Z
actor:
  - agent: claude-code
    terminal: t28
---
**At c643310: swift test 21 tests in 6 suites pass (Swift 6, no data-race diagnostics), including 3.0-style struct and actor plugins in a target that doesn't import Plugin receiving 500 entries in order, and Scribe plugins registered one at a time into Plugin's Plugins and run with handleInOrder; specsync check --strict passes; the DocC archive built with --hosting-base-path Scribe references /Scribe/js.**

Recorded as passed in local-macos-arm64 at revision c64331009b6b, observed 2026-11-16T03:29:20Z.
