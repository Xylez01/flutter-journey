import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'migration_report.dart';

abstract class Storage {
  Future<List<MigrationReport>> read();

  Future<void> write(List<MigrationReport> reports);
}

class FileStorage implements Storage {
  FileStorage({this.async = true, this.directory = "journey"});

  final bool async;
  final String directory;

  String? _rootDirectory;

  Future<String> get rootDirectory async =>
      _rootDirectory ??= (await getApplicationDocumentsDirectory()).path + "/$directory";

  @override
  Future<List<MigrationReport>> read() async {
    return await _readAndParse(await rootDirectory);
  }

  @override
  Future<void> write(List<MigrationReport> reports) async {
    final arguments = _WriteReportsArguments(reports: reports, rootDirectory: await rootDirectory);

    if (async) {
      compute(_parseAndWrite, arguments);
    } else {
      await _parseAndWrite(arguments);
    }
  }

  static Future<List<MigrationReport>> _readAndParse(String rootDirectory) async {
    final file = await _reportsFile(rootDirectory);
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

  static Future<void> _parseAndWrite(_WriteReportsArguments arguments) async {
    final currentReports = await _readAndParse(arguments.rootDirectory)
      ..removeWhere((report) => arguments.reports.any((newReport) => newReport.migrationId == report.migrationId));

    final joinedReports = [...currentReports, ...arguments.reports];

    final json = jsonEncode(
      joinedReports
          .map((report) => {
                "migrationId": report.migrationId,
                "executedOn": report.executedOn.toIso8601String(),
                "result": report.result.name,
                "errorMessage": report.errorMessage,
              })
          .toList(),
    );

    final file = await _reportsFile(arguments.rootDirectory);
    await file.writeAsString(json, mode: FileMode.write);
  }

  static Future<File> _reportsFile(String rootDirectory) async {
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

class _WriteReportsArguments {
  _WriteReportsArguments({required this.reports, required this.rootDirectory});

  final List<MigrationReport> reports;
  final String rootDirectory;
}
