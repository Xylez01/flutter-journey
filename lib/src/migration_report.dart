import 'package:meta/meta.dart';

enum MigrationResult {
  successful,
  failed,
  skipped,
  unknown,
}

extension MigrationResultExtension on MigrationResult {
  String get name {
    switch (this) {
      case MigrationResult.successful:
        return "successful";
      case MigrationResult.failed:
        return "failed";
      case MigrationResult.unknown:
        return "unknown";
      case MigrationResult.skipped:
        return "skipped";
    }
  }
}

MigrationResult parseMigrationResult(String? value) {
  if (value == null || value.isEmpty) {
    return MigrationResult.unknown;
  }

  return MigrationResult.values.singleWhere((enumValue) => enumValue.name == value);
}

@immutable
class MigrationReport {
  const MigrationReport({
    required this.migrationId,
    required this.executedOn,
    required this.result,
    this.errorMessage,
  });

  factory MigrationReport.withResult({required String migrationId, required MigrationResult result}) => MigrationReport(
        migrationId: migrationId,
        executedOn: DateTime.now().toUtc(),
        result: result,
      );

  factory MigrationReport.failed({required String migrationId, required String errorMessage}) => MigrationReport(
        migrationId: migrationId,
        executedOn: DateTime.now().toUtc(),
        result: MigrationResult.failed,
        errorMessage: errorMessage,
      );

  final String migrationId;
  final DateTime executedOn;
  final MigrationResult result;
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationReport &&
          runtimeType == other.runtimeType &&
          migrationId == other.migrationId &&
          executedOn == other.executedOn &&
          result == other.result &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => migrationId.hashCode ^ executedOn.hashCode ^ result.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    return 'MigrationReport{migrationId: $migrationId, executedOn: $executedOn, result: $result, errorMessage: $errorMessage}';
  }
}
