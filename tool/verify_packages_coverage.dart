// Enforces a minimum line-coverage percentage per package under packages/.
// The example app is intentionally excluded (see CI / README).
//
// Usage (from repo root): dart run tool/verify_packages_coverage.dart
// Optional: COVERAGE_MIN_PERCENT=90 (default 90)

import 'dart:io';

import 'package:lcov_parser/lcov_parser.dart';

const _defaultMinPercent = 90.0;

final _excludeSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.part.dart',
];

/// Declarative Drift table/schema definitions (column getters are not executed
/// as regular statements the way application logic is).
final _excludePathSuffixes = <String>[
  '/health_cache_database.dart',
];

Future<void> main() async {
  final minPercent = double.tryParse(
        Platform.environment['COVERAGE_MIN_PERCENT'] ?? '',
      ) ??
      _defaultMinPercent;

  final root = Directory.current;
  final packagesDir = Directory('${root.path}/packages');
  if (!packagesDir.existsSync()) {
    stderr.writeln('No packages/ directory (run from repo root).');
    exit(2);
  }

  var failed = false;
  final rows = <String>[];

  for (final entity in packagesDir.listSync().whereType<Directory>()) {
    final lcovFile = File('${entity.path}/coverage/lcov.info');
    if (!lcovFile.existsSync()) {
      continue;
    }

    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final records = await Parser.parse(lcovFile.path);

    var hits = 0;
    var found = 0;
    for (final r in records) {
      final path = r.file;
      if (path == null || path.isEmpty) {
        continue;
      }
      if (_excludeSuffixes.any(path.endsWith)) {
        continue;
      }
      if (_excludePathSuffixes.any(path.endsWith)) {
        continue;
      }
      hits += r.lines?.hit ?? 0;
      found += r.lines?.found ?? 0;
    }

    final pct = found == 0 ? 100.0 : (hits / found) * 100;
    final pctCol = '${pct.toStringAsFixed(1)}%'.padLeft(6);
    rows.add('$pctCol  $hits/$found  $name');

    if (found > 0 && pct + 1e-6 < minPercent) {
      stderr.writeln(
        '[FAIL] $name: ${pct.toStringAsFixed(1)}% < $minPercent% '
        '(after excluding generated suffixes)',
      );
      failed = true;
    }
  }

  stdout.writeln('Package line coverage (min $minPercent%):');
  rows
    ..sort()
    ..forEach(stdout.writeln);

  if (failed) {
    exit(1);
  }
  stdout.writeln('[OK] All packages with coverage meet >= $minPercent%.');
}
