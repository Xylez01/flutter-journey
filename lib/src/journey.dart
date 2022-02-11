import 'migration.dart';
import 'migration_report.dart';
import 'storage.dart';

class Journey {
  Journey({
    required List<Migration> migrations,
    Storage? storage,
  })  : _migrations = migrations,
        _storage = storage ?? AsyncFileStorage();

  final List<Migration> _migrations;
  final Storage _storage;

  Future<List<MigrationReport>> migrate() async {
    final previousMigrations = (await _storage.read()).map((report) => report.migrationId).toList();

    final reports = <MigrationReport>[];

    for (var migration in _migrations.where((migration) => !previousMigrations.contains(migration.id))) {
      try {
        final result = await migration.run();

        reports.add(MigrationReport.withResult(migrationId: migration.id, result: result));
      } on Exception catch (exception) {
        reports.add(MigrationReport.failed(migrationId: migration.id, errorMessage: exception.toString()));
      }
    }

    _storage.write(reports);

    return reports;
  }
}
