---
name: versioning
description: Bump the flutter_agent_lints version and write its changelog entry.
disable-model-invocation: true
---

# Versioning

The version is decided by the effective rule set, because for a consumer any
change to it is a build break, whatever the diff looks like.

## Decide the bump

1. Diff the effective rule set against the last release tag: the `true` and
   `false` entries in `lib/analysis_options.yaml` and `lib/experimental.yaml`
   plus the generated `analyzer.errors` blocks.
2. A rule added, removed, or changed in severity: **major**. A new SDK minor
   that brings new rules, or a rule the SDK deprecated and we removed, is
   this case even when the decision was `false`.
3. Rule set unchanged, but the SDK lower bound, the analyzer pin, or the
   tooling moved: **minor**.
4. Only docs, example, or CI: **patch**, or no release.

## Move the SDK bound with a major

`environment: sdk` in `pubspec.yaml` is the SDK whose rule set the files
enumerate. On a major caused by a new SDK it moves to that SDK's minor
(`^3.14.0`), never to a patch: a patch bound would lock out consumers whose
Flutter bundles an older patch for no rule change. The `analyzer` dev
dependency is pinned to the version bundled with that SDK:
`pkg/analyzer/pubspec.yaml` at the SDK tag, with `-dev` stripped.

## Write the changelog entry

Add `## <version>` at the top of `CHANGELOG.md`, one line per item: every
added rule with its decision and reason, every removed rule and why, the new
SDK lower bound. A minor or patch states in one line what moved.

## Done when

- `version` in `pubspec.yaml` equals the top heading of `CHANGELOG.md`.
- `dart run tool/generate.dart --check` and `dart run tool/check_rules.dart`
  pass.
