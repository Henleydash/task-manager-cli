import 'dart:io';

import 'package:task_manager_cli/src/cli.dart';
import 'package:task_manager_cli/src/exceptions.dart';
import 'package:task_manager_cli/src/task_repository.dart';

Future<void> main(List<String> arguments) async {
  final repository = JsonTaskRepository('tasks.json');
  final cli = Cli(repository);

  try {
    await cli.run(arguments);
  } on TaskException catch (e) {
    stderr.writeln('Erreur: $e');
    exit(1);
  }
}
