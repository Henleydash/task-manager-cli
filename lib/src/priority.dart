import 'exceptions.dart';

/// The urgency level of a [Task].
enum Priority { low, medium, high }

/// Parses a raw CLI string (e.g. "high") into a [Priority] value.
///
/// Throws an [InvalidTaskDataException] if the string does not match
/// one of the known priority levels.
Priority priorityFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'low':
      return Priority.low;
    case 'medium':
      return Priority.medium;
    case 'high':
      return Priority.high;
    default:
      throw InvalidTaskDataException(
        'Priorité invalide: "$raw". Valeurs attendues: low, medium, high.',
      );
  }
}

/// Converts a [Priority] back into its lowercase string representation,
/// used both for display and for JSON persistence.
String priorityToString(Priority priority) => priority.name;

/// Numeric weight used for sorting tasks from most to least urgent.
int priorityWeight(Priority priority) {
  switch (priority) {
    case Priority.high:
      return 3;
    case Priority.medium:
      return 2;
    case Priority.low:
      return 1;
  }
}
