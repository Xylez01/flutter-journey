import 'migration_report.dart';

/// A migration that will only be executed once.
abstract class Migration {
  /// A unique identifier for the [Migration] that does not change over time
  String get id;

  /// Execute the migration and return a [MigrationResult] indicating the result.
  Future<MigrationResult> run();
}
