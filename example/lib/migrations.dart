import 'package:journey/journey.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrateToNewBackgroundImage extends Migration {
  MigrateToNewBackgroundImage({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  String get id => runtimeType.toString();

  @override
  Future<MigrationResult> migrate() async {
    await sharedPreferences.setString(
      "background_image",
      "background-yellow.jpg",
    );

    return MigrationResult.successful;
  }

  @override
  Future<void> rollback() async {
    await sharedPreferences.setString(
      "background_image",
      "background-purple.jpg",
    );
  }
}

class MigrateToNewStyle extends Migration {
  MigrateToNewStyle({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  String get id => runtimeType.toString();

  @override
  Future<MigrationResult> migrate() async {
    await sharedPreferences.setString(
      "app_name",
      "JOURNEY 🤩",
    );

    return MigrationResult.successful;
  }

  @override
  Future<void> rollback() async {
    await sharedPreferences.setString(
      "app_name",
      "Journey",
    );
  }
}
