import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'exceptions.dart';
import 'repository.dart';
import 'task.dart';

/// Persists [Task]s as a JSON array in a local file.
///
/// Implements the generic [Repository] interface (`Repository<Task>`),
/// giving the CLI a storage layer it can swap out (e.g. for an in-memory
/// or database-backed repository in tests) without changing calling code.
class JsonTaskRepository implements Repository<Task> {
  final String filePath;

  JsonTaskRepository(this.filePath);

  File get _file => File(filePath);

  @override
  Future<List<Task>> getAll() async {
    if (!await _file.exists()) return [];

    final raw = await _file.readAsString();
    if (raw.trim().isEmpty) return [];

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw InvalidTaskDataException(
        'Le fichier de données "$filePath" est corrompu (JSON invalide): ${e.message}',
      );
    }

    if (decoded is! List) {
      throw InvalidTaskDataException(
        'Le fichier de données "$filePath" doit contenir un tableau JSON.',
      );
    }

    return decoded
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(Task item) async {
    final tasks = await getAll();
    tasks.add(item);
    await _save(tasks);
  }

  @override
  Future<void> update(Task item) async {
    final tasks = await getAll();
    final index = tasks.indexWhere((t) => t.id == item.id);
    if (index == -1) throw TaskNotFoundException(item.id);
    tasks[index] = item;
    await _save(tasks);
  }

  @override
  Future<void> delete(String id) async {
    final tasks = await getAll();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    tasks.removeAt(index);
    await _save(tasks);
  }

  /// Convenience wrapper around [update] that just flips `completed`.
  Future<void> markDone(String id) async {
    final tasks = await getAll();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    tasks[index].completed = true;
    await _save(tasks);
  }

  Future<void> _save(List<Task> tasks) async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );
  }
}

/// Generates a short, sufficiently-unique id for new tasks
/// (timestamp + random suffix, no external uuid dependency needed).
String generateTaskId() {
  final millis = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = Random().nextInt(0xFFFFFF).toRadixString(36).padLeft(4, '0');
  return '$millis$rand';
}
