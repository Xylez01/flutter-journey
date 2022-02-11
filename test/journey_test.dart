import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journey/journey.dart';
import 'package:journey/src/storage.dart';

void main() {
  group("$Journey", () {
    setUp(() {
      const MethodChannel pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      const MethodChannel pathProviderMacOSChannel =
          MethodChannel('plugins.flutter.io/path_provider_macos');

      handler(MethodCall methodCall) async {
        if (methodCall.method == "getApplicationDocumentsDirectory") {
          return "./test";
        }

        return null;
      }

      TestWidgetsFlutterBinding.ensureInitialized();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, handler);

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderMacOSChannel, handler);
    });

    Future<List<MigrationReport>> runJourney({
      required List<Migration> migrations,
    }) async {
      final journey = Journey(
        migrations: migrations,
        storage: FileStorage(async: false),
      );
      return await journey.migrate();
    }

    group("when running migrations for the first time", () {
      late List<MigrationReport> reports;

      setUp(() async {
        reports = await runJourney(migrations: [
          _MigrationOne(),
          _MigrationTwo(),
        ]);
      });

      test("then every migration is executed", () {
        expect(reports.length, 2);
      });

      test("then there is a report for $_MigrationOne", () {
        expect(reports[0].migrationId, equals("migration_one"));
        expect(reports[0].result, equals(MigrationResult.successful));
      });

      test("then there is a report for $_MigrationTwo", () {
        expect(reports[1].migrationId, equals("migration_two"));
        expect(reports[1].result, equals(MigrationResult.skipped));
      });

      group("and when the same journey is executed", () {
        setUp(() async {
          reports = await runJourney(migrations: [
            _MigrationOne(),
            _MigrationTwo(),
          ]);
        });

        test("then no migrations are executed", () {
          expect(reports.length, 0);
        });
      });

      group("and when another migration is added to the journey", () {
        setUp(() async {
          reports = await runJourney(migrations: [
            _MigrationOne(),
            _MigrationTwo(),
            _MigrationThree(),
          ]);
        });

        test("then only this new migration is executed", () {
          expect(reports.length, 1);
          expect(reports[0].migrationId, equals("migration_three"));
        });
      });
    });

    group("when one migration fails", () {
      late List<MigrationReport> reports;

      setUp(() async {
        reports = await runJourney(migrations: [
          _MigrationOne(),
          _FaultyMigration(),
          _MigrationTwo(),
        ]);
      });

      test("then all migrations are executed", () {
        expect(reports.length, 3);
      });

      test("then only the faulty migration is reported as failing", () {
        expect(
          reports
              .where((report) => report.result == MigrationResult.failed)
              .length,
          equals(1),
        );
      });
    });

    tearDown(() {
      final directory = Directory("./test/journey");
      if (!directory.existsSync()) {
        return;
      }

      final reportsFile = File("${directory.path}/reports.json");
      if (reportsFile.existsSync()) {
        reportsFile.deleteSync();
      }

      directory.deleteSync();
    });
  });
}

class _MigrationOne implements Migration {
  @override
  String get id => "migration_one";

  @override
  Future<MigrationResult> run() async {
    return MigrationResult.successful;
  }
}

class _MigrationTwo implements Migration {
  @override
  String get id => "migration_two";

  @override
  Future<MigrationResult> run() async {
    return MigrationResult.skipped;
  }
}

class _MigrationThree implements Migration {
  @override
  String get id => "migration_three";

  @override
  Future<MigrationResult> run() async {
    return MigrationResult.successful;
  }
}

class _FaultyMigration implements Migration {
  @override
  String get id => "faulty_migration";

  @override
  Future<MigrationResult> run() async {
    throw Exception("ow no");
  }
}
