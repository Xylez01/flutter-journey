import 'migration_report.dart';

abstract class Migration {
  String get id;

  Future<MigrationResult> run();
}
