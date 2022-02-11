import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'migration_report.dart';

abstract class Storage {
  Future<List<MigrationReport>> read();

  Future<void> write(List<MigrationReport> reports);
}

class FileStorage implements Storage {
  FileStorage({
    this.async = true,
    String directory = "journey",
  }) : _directory = directory;

  final bool async;

  Future<String> get rootDirectory async =>
      _rootDirectory ??= (await getApplicationDocumentsDirectory()).path + "/$_directory";

  final String _directory;
  String? _rootDirectory;
  List<MigrationReport>? _reports;

  @override
  Future<List<MigrationReport>> read() async {
    _reports = await _readAndParse(await rootDirectory);
    return _reports!;
  }

  @override
  Future<void> write(List<MigrationReport> reports) async {
    if (_reports == null) {
      await read();
    }

    final currentReports = _reports!
      ..removeWhere((report) => reports.any((newReport) => newReport.migrationId == report.migrationId));

    _reports = [...currentReports, ...reports];

    if (async) {
      _parseAndWrite(reports: _reports!, rootDirectory: await rootDirectory);
    } else {
      await _parseAndWrite(reports: _reports!, rootDirectory: await rootDirectory);
    }
  }

  Future<List<MigrationReport>> _readAndParse(String rootDirectory) async {
    final file = await _getReportsFile(rootDirectory);
    var content = await file.readAsString();

    if (content.isEmpty) {
      content = "[]";
    }

    return (jsonDecode(content) as List<dynamic>).map(
      (element) {
        return MigrationReport(
          migrationId: element["migrationId"]!.toString(),
          executedOn: DateTime.parse(element["executedOn"]!.toString()),
          result: parseMigrationResult(element["result"]?.toString()),
          errorMessage: element["errorMessage"]?.toString(),
        );
      },
    ).toList();
  }

  Future<void> _parseAndWrite({
    required List<MigrationReport> reports,
    required String rootDirectory,
  }) async {
    final json = jsonEncode(
      reports
          .map((report) => {
                "migrationId": report.migrationId,
                "executedOn": report.executedOn.toIso8601String(),
                "result": report.result.name,
                "errorMessage": report.errorMessage,
              })
          .toList(),
    );

    final file = await _getReportsFile(rootDirectory);
    await file.writeAsString(json, mode: FileMode.write);
  }

  Future<File> _getReportsFile(String rootDirectory) async {
    final directory = Directory(rootDirectory);

    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final file = File("${directory.path}/reports.json");

    if (!(await file.exists())) {
      await file.create();
    }

    return file;
  }
}
