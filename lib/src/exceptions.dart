/// Base class for every error raised by this application.
///
/// Extending [Exception] (rather than [Error]) signals that these are
/// expected, recoverable failure conditions (bad input, missing task, a
/// corrupted data file) that calling code is meant to catch and handle,
/// as opposed to programmer bugs.
abstract class TaskException implements Exception {
  final String message;
  TaskException(this.message);

  @override
  String toString() => message;
}

/// Thrown when an operation refers to a task id that does not exist
/// in the repository (e.g. marking a non-existent task as done).
class TaskNotFoundException extends TaskException {
  final String taskId;
  TaskNotFoundException(this.taskId)
      : super('Aucune tâche trouvée avec l\'identifiant "$taskId".');
}

/// Thrown when task data supplied by the user or read from disk is
/// malformed: an unknown priority, an unparsable date, missing fields,
/// or a corrupted JSON file.
class InvalidTaskDataException extends TaskException {
  InvalidTaskDataException(String message) : super(message);
}

/// Thrown when the CLI is invoked with an unknown command or with
/// missing/incorrect arguments for a known command.
class InvalidCommandException extends TaskException {
  InvalidCommandException(String message) : super(message);
}
