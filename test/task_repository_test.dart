import 'dart:io';

import 'package:task_manager_cli/src/exceptions.dart';
import 'package:task_manager_cli/src/priority.dart';
import 'package:task_manager_cli/src/task.dart';
import 'package:task_manager_cli/src/task_repository.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String tasksPath;
  late JsonTaskRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('task_manager_test_');
    tasksPath = '${tempDir.path}/tasks.json';
    repository = JsonTaskRepository(tasksPath);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('getAll on a missing file returns an empty list', () async {
    final tasks = await repository.getAll();
    expect(tasks, isEmpty);
  });

  test('add persists a task that can be read back', () async {
    final task = StandardTask(id: 't1', title: 'Acheter du lait', priority: Priority.medium);
    await repository.add(task);

    final tasks = await repository.getAll();
    expect(tasks, hasLength(1));
    expect(tasks.first.id, 't1');
    expect(tasks.first.title, 'Acheter du lait');
    expect(tasks.first.completed, isFalse);
  });

  test('markDone flips the completed flag of the right task', () async {
    await repository.add(StandardTask(id: 't1', title: 'A', priority: Priority.low));
    await repository.add(StandardTask(id: 't2', title: 'B', priority: Priority.high));

    await repository.markDone('t2');

    final tasks = await repository.getAll();
    expect(tasks.firstWhere((t) => t.id == 't1').completed, isFalse);
    expect(tasks.firstWhere((t) => t.id == 't2').completed, isTrue);
  });

  test('delete removes a task', () async {
    await repository.add(StandardTask(id: 't1', title: 'A', priority: Priority.low));
    await repository.delete('t1');

    final tasks = await repository.getAll();
    expect(tasks, isEmpty);
  });

  test('delete on an unknown id throws TaskNotFoundException', () async {
    await expectLater(
      repository.delete('does-not-exist'),
      throwsA(isA<TaskNotFoundException>()),
    );
  });

  test('markDone on an unknown id throws TaskNotFoundException', () async {
    await expectLater(
      repository.markDone('does-not-exist'),
      throwsA(isA<TaskNotFoundException>()),
    );
  });

  test('invalid priority string throws InvalidTaskDataException', () {
    expect(() => priorityFromString('urgentissime'), throwsA(isA<InvalidTaskDataException>()));
  });

  test('UrgentTask round-trips through JSON including its extra field', () async {
    final urgent = UrgentTask(
      id: 'u1',
      title: 'Déployer le correctif',
      priority: Priority.high,
      dueDate: DateTime(2026, 1, 1),
      escalationHours: 6,
    );
    await repository.add(urgent);

    final tasks = await repository.getAll();
    final reloaded = tasks.single as UrgentTask;
    expect(reloaded.escalationHours, 6);
    expect(reloaded.typeName, 'urgent');
    expect(reloaded.dueDate, DateTime(2026, 1, 1));
  });

  test('a corrupted JSON file raises InvalidTaskDataException', () async {
    File(tasksPath).writeAsStringSync('{not valid json');
    await expectLater(repository.getAll(), throwsA(isA<InvalidTaskDataException>()));
  });

  test('empty title is rejected when constructing a task', () {
    expect(
      () => StandardTask(id: 'x', title: '   ', priority: Priority.low),
      throwsA(isA<InvalidTaskDataException>()),
    );
  });
}
