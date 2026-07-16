import 'exceptions.dart';
import 'priority.dart';

/// Base type for every item managed by the application.
///
/// [Task] is abstract: it defines the shared shape and behaviour (id,
/// title, priority, due date, completion state, JSON round-tripping)
/// but leaves [typeName] and the urgency banner shown by [describe] to
/// concrete subclasses.
abstract class Task {
  final String id;
  String title;
  Priority priority;
  DateTime? dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.dueDate,
    this.completed = false,
  }) {
    if (title.trim().isEmpty) {
      throw InvalidTaskDataException('Le titre de la tâche ne peut pas être vide.');
    }
  }

  /// Discriminator persisted to JSON so [Task.fromJson] can rebuild the
  /// correct subclass.
  String get typeName;

  /// Short human-readable label prepended when a task is printed. Overridden
  /// by [UrgentTask] to make deadlines stand out in the CLI output.
  String describe();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priorityToString(priority),
        'dueDate': dueDate?.toIso8601String(),
        'completed': completed,
        'type': typeName,
      };

  /// Rebuilds the correct [Task] subclass from a JSON map, as produced
  /// by [toJson]. Throws [InvalidTaskDataException] for malformed data.
  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String;
      final title = json['title'] as String;
      final priority = priorityFromString(json['priority'] as String);
      final dueDateRaw = json['dueDate'] as String?;
      final dueDate = dueDateRaw == null ? null : DateTime.parse(dueDateRaw);
      final completed = json['completed'] as bool? ?? false;
      final type = json['type'] as String? ?? 'standard';

      switch (type) {
        case 'urgent':
          final hours = json['escalationHours'] as int? ?? 24;
          return UrgentTask(
            id: id,
            title: title,
            priority: priority,
            dueDate: dueDate,
            completed: completed,
            escalationHours: hours,
          );
        case 'standard':
          return StandardTask(
            id: id,
            title: title,
            priority: priority,
            dueDate: dueDate,
            completed: completed,
          );
        default:
          throw InvalidTaskDataException('Type de tâche inconnu: "$type".');
      }
    } on InvalidTaskDataException {
      rethrow;
    } catch (e) {
      throw InvalidTaskDataException('Impossible de lire la tâche: $e');
    }
  }

  @override
  String toString() {
    final status = completed ? '[x]' : '[ ]';
    final due = dueDate == null ? '' : ' (échéance: ${_fmtDate(dueDate!)})';
    return '$status ${describe()} — ${priorityToString(priority)}$due  <${id.substring(0, 8)}>';
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// A regular task with no special escalation behaviour.
class StandardTask extends Task {
  StandardTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.completed,
  });

  @override
  String get typeName => 'standard';

  @override
  String describe() => title;
}

/// A task that additionally tracks how many hours before its due date
/// it should be escalated. Demonstrates inheritance (Task -> UrgentTask)
/// with an added field and overridden behaviour.
class UrgentTask extends Task {
  /// How many hours before [dueDate] this task is considered escalated.
  final int escalationHours;

  UrgentTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.completed,
    this.escalationHours = 24,
  });

  /// True once we are within [escalationHours] of the due date and the
  /// task is not yet completed.
  bool get isEscalated {
    if (completed || dueDate == null) return false;
    final hoursLeft = dueDate!.difference(DateTime.now()).inHours;
    return hoursLeft <= escalationHours;
  }

  @override
  String get typeName => 'urgent';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'escalationHours': escalationHours,
      };

  @override
  String describe() => isEscalated ? '⚠ URGENT: $title' : '$title';
}
