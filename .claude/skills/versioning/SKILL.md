---
name: versioning
description: Bump the flutter_agent_lints version and write its changelog entry.
disable-model-invocation: true
---

# Versioning

The version follows what consumers can observe, nothing else. A release
exists only when the analysis a consumer gets, or the SDK they need, changed.

## Decide the bump

Run the script; it is the decision, not a hint:

```bash
dart run .claude/skills/versioning/scripts/bump.dart
```

It compares the shipped files under `lib/` and `environment: sdk` in
`pubspec.yaml` against the last `v*` tag and prints `bump`, `next`, and one
`reason` line per difference. The rules it applies:

- Any semantic change to a shipped file (parsed YAML, so comment edits do not
  count): **major**. Consumers' analysis changes, which is a build break.
- Rule set unchanged, SDK lower bound moved: **minor**.
- Neither: **none**. Docs, tooling, CI, and the example are invisible to
  consumers and get no release.
- Exception the script cannot see: a packaging-only fix that changes what
  consumers download (for example the archive contents) is a **patch**,
  decided by hand.
- No tag yet: **initial**; release the version already in `pubspec.yaml`.

## Move the SDK bound with a major

On a major caused by a new SDK, `environment: sdk` moves to that SDK's minor
(`^3.14.0`), never to a patch: a patch bound would lock out consumers whose
Flutter bundles an older patch for no rule change. The `analyzer` dev
dependency is pinned to the version bundled with that SDK:
`pkg/analyzer/pubspec.yaml` at the SDK tag, with `-dev` stripped.

## Write the changelog entry

Set `version` in `pubspec.yaml` to `next` and add `## <next>` at the top of
`CHANGELOG.md`, one line per item: every rule added with its decision and
reason, every rule removed and why, the new SDK lower bound. A minor states in
one line what moved.

## Done when

- The script prints `bump: none` against a tag named after the new version,
  or, before tagging, `version` in `pubspec.yaml` equals its `next` and the
  top heading of `CHANGELOG.md`.
- `dart run tool/generate.dart --check` and `dart run tool/check_rules.dart`
  pass.
