import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'migration_report.dart';

/// A storage used to read and store the [MigrationReport]s
abstract class Storage {
  /// Get all [MigrationReport]s
  Future<List<MigrationReport>> getAll();

  /// Store the (new) [reports]
  Future<void> store(List<MigrationReport> reports);
}

/// [Storage] implementation that uses a [File]
class FileStorage implements Storage {
  /// Create a file storage
  ///
  /// By default [async] is true, which means write actions are not awaited.
  /// Setting [async] to false means write actions are awaited.
  ///
  /// By default the [directory] is set to "journey".
  FileStorage({
    bool async = true,
    String directory = "journey",
  })  : _async = async,
        _directory = directory;

  final bool _async;

  final String _directory;

  String? _rootDirectory;

  List<MigrationReport>? _reports;

  Future<String> get _onDeviceDirectory async => _rootDirectory ??=
      (await getApplicationDocumentsDirectory()).path + "/$_directory";

  @override
  Future<List<MigrationReport>> getAll() async {
    _reports = await _readAndParse(await _onDeviceDirectory);
    return _reports!;
  }

  @override
  Future<void> store(List<MigrationReport> reports) async {
    _reports = reports;

    if (_async) {
      _parseAndWrite(
          reports: _reports!, rootDirectory: await _onDeviceDirectory);
    } else {
      await _parseAndWrite(
          reports: _reports!, rootDirectory: await _onDeviceDirectory);
    }
  }

  Future<List<MigrationReport>> _readAndParse(String rootDirectory) async {
    final file = await _getReportsFile(rootDirectory);
    var content = await file.readAsString();

    if (content.isEmpty) {
      content = "[]";
    }

    return (jsonDecode(content) as List<dynamic>)
        .map((element) =>
            MigrationReport.decode(element as Map<String, Object?>))
        .toList();
  }

  Future<void> _parseAndWrite({
    required List<MigrationReport> reports,
    required String rootDirectory,
  }) async {
    final json = jsonEncode(reports.map((report) => report.encode()).toList());
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
