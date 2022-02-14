import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journey/journey.dart';
import 'package:journey/src/storage.dart';

void main() {
  group("$Journey benchmark", () {
    const iterations = 1000;

    setUp(() {
      const MethodChannel pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      const MethodChannel pathProviderMacOSChannel =
          MethodChannel('plugins.flutter.io/path_provider_macos');

      handler(MethodCall methodCall) async {
        if (methodCall.method == "getApplicationDocumentsDirectory") {
          return "./benchmark_out";
        }

        return null;
      }

      TestWidgetsFlutterBinding.ensureInitialized();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, handler);

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderMacOSChannel, handler);
    });

    void cleanUp() {
      final directory = Directory("./benchmark_out");
      if (directory.existsSync()) {
        directory
            .listSync()
            .forEach((entity) => entity.deleteSync(recursive: true));
      }

      directory.deleteSync(recursive: true);
    }

    Future<void> runJourney({required bool async, required int count}) async {
      final journey = Journey(
        migrations: [
          _MigrationOne(),
          _MigrationTwo(),
          _MigrationThree(),
        ],
        storage: FileStorage(
          async: async,
          directory: "journey_$count",
        ),
      );

      await journey.migrate();
    }

    group("with FileStorage(async: false)", () {
      test("execute benchmark", () async {
        final stopwatch = Stopwatch()..start();

        for (var count = 0; count < iterations; count++) {
          await runJourney(async: false, count: count);
        }

        stopwatch.stop();

        // ignore: avoid_print
        print("Executed benchmark in ${stopwatch.elapsed}");
      });

      tearDown(() => cleanUp());
    });

    group("with FileStorage(async: true)", () {
      test("execute benchmark", () async {
        final stopwatch = Stopwatch()..start();

        for (var count = 0; count < iterations; count++) {
          await runJourney(async: true, count: count);
        }

        stopwatch.stop();

        // ignore: avoid_print
        print("Executed benchmark in ${stopwatch.elapsed}");
      });

      tearDown(() => cleanUp());
    });
  });
}

class _MigrationOne extends Migration {
  @override
  String get id => "migration_one";

  @override
  Future<MigrationResult> migrate() async {
    return MigrationResult.successful;
  }
}

class _MigrationTwo extends Migration {
  @override
  String get id => "migration_two";

  @override
  Future<MigrationResult> migrate() async {
    return MigrationResult.skipped;
  }
}

class _MigrationThree extends Migration {
  @override
  String get id => "migration_three";

  @override
  Future<MigrationResult> migrate() async {
    return MigrationResult.successful;
  }
}
