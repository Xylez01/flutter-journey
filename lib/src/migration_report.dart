import 'package:meta/meta.dart';

/// Migration result values used to indicate migration results
enum MigrationResult {
  /// Migration was successful
  successful,

  /// Migration failed
  failed,

  /// Migration was skipped because it was unnecessary
  skipped,
}

/// Extension on [MigrationResult] to polyfill the [name]
extension MigrationResultExtension on MigrationResult {
  /// Get the name of the result. Used for encoding/decoding.
  String get name {
    switch (this) {
      case MigrationResult.successful:
        return "successful";
      case MigrationResult.failed:
        return "failed";
      case MigrationResult.skipped:
        return "skipped";
    }
  }
}

/// Parses the name of a [MigrationResult] to a [MigrationResult]
MigrationResult parseMigrationResult(String? value) {
  if (value == null || value.isEmpty) {
    return MigrationResult.skipped;
  }

  return MigrationResult.values.singleWhere((enumValue) => enumValue.name == value);
}

/// Migration report containing the id, status and when it was executed (in UTC)
@immutable
class MigrationReport {
  /// Create a new [MigrationReport]
  /// If the [result] is [MigrationResult.failed], then the [errorMessage] is expected.
  const MigrationReport._({
    required this.migrationId,
    required this.executedOn,
    required this.result,
    this.errorMessage,
  });

  /// Create a new report for the given [result]
  factory MigrationReport.withResult({required String migrationId, required MigrationResult result}) =>
      MigrationReport._(
        migrationId: migrationId,
        executedOn: DateTime.now().toUtc(),
        result: result,
      );

  /// Create a report for a failed migration
  factory MigrationReport.failed({required String migrationId, required String errorMessage}) => MigrationReport._(
        migrationId: migrationId,
        executedOn: DateTime.now().toUtc(),
        result: MigrationResult.failed,
        errorMessage: errorMessage,
      );

  /// Decode a report from json
  factory MigrationReport.decode(Map<String, Object?> json) => MigrationReport._(
        migrationId: json["migrationId"]!.toString(),
        executedOn: DateTime.parse(json["executedOn"]!.toString()),
        result: parseMigrationResult(json["result"]?.toString()),
        errorMessage: json["errorMessage"]?.toString(),
      );

  /// The unique if of the migration
  final String migrationId;

  /// The date and time of execution in UTC
  final DateTime executedOn;

  /// The result of the migration
  final MigrationResult result;

  /// The error message of the migration failed
  final String? errorMessage;

  /// Encode the report in json format
  Map<String, Object?> encode() => {
        "migrationId": migrationId,
        "executedOn": executedOn.toIso8601String(),
        "result": result.name,
        "errorMessage": errorMessage,
      };

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
