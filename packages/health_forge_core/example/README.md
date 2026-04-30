# health_forge_core example

Pure Dart, runnable as-is:

```bash
dart run example/example.dart
```

The example constructs two overlapping `HeartRateSample` records — one from
Apple, one from Oura — and resolves the conflict via `MergeEngine` configured
with the priority-based strategy (Apple ranked above Oura). It prints the
resolved record count and any conflict reports.

For a richer end-to-end demo with multiple providers and queries, see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.
