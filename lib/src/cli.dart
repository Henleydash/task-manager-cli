import 'exceptions.dart';
import 'priority.dart';
import 'task.dart';
import 'task_repository.dart';

/// Wires CLI arguments to the [JsonTaskRepository] and prints results.
class Cli {
  final JsonTaskRepository repository;

  Cli(this.repository);

  Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      _printHelp();
      return;
    }

    final command = args.first;
    final rest = args.skip(1).toList();

    switch (command) {
      case 'add':
        await _add(rest);
        break;
      case 'list':
        await _list(rest);
        break;
      case 'done':
        await _done(rest);
        break;
      case 'delete':
        await _delete(rest);
        break;
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        break;
      default:
        throw InvalidCommandException('Commande inconnue: "$command". Tape "help" pour la liste des commandes.');
    }
  }

  Future<void> _add(List<String> args) async {
    if (args.length < 2) {
      throw InvalidCommandException(
        'Usage: add "<titre>" <low|medium|high> [dueDate:AAAA-MM-JJ] [--urgent] [--escalation=<heures>]',
      );
    }

    final title = args[0];
    final priority = priorityFromString(args[1]);

    DateTime? dueDate;
    bool urgent = false;
    int escalationHours = 24;

    for (final arg in args.skip(2)) {
      if (arg == '--urgent') {
        urgent = true;
      } else if (arg.startsWith('--escalation=')) {
        escalationHours = int.tryParse(arg.split('=').last) ??
            (throw InvalidCommandException('Valeur d\'escalade invalide: "$arg"'));
      } else {
        try {
          dueDate = DateTime.parse(arg);
        } catch (_) {
          throw InvalidTaskDataException('Date invalide: "$arg". Format attendu AAAA-MM-JJ.');
        }
      }
    }

    final id = generateTaskId();
    final task = urgent
        ? UrgentTask(
            id: id,
            title: title,
            priority: priority,
            dueDate: dueDate,
            escalationHours: escalationHours,
          )
        : StandardTask(
            id: id,
            title: title,
            priority: priority,
            dueDate: dueDate,
          );

    await repository.add(task);
    print('Tâche ajoutée: $task');
  }

  Future<void> _list(List<String> args) async {
    final tasks = await repository.getAll();
    if (tasks.isEmpty) {
      print('Aucune tâche pour le moment.');
      return;
    }

    String sortBy = 'priority';
    for (final arg in args) {
      if (arg.startsWith('--sort=')) {
        sortBy = arg.split('=').last;
      }
    }

    final sorted = [...tasks];
    if (sortBy == 'date') {
      sorted.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else if (sortBy == 'priority') {
      sorted.sort((a, b) => priorityWeight(b.priority).compareTo(priorityWeight(a.priority)));
    } else {
      throw InvalidCommandException('Tri inconnu: "$sortBy". Utilise "priority" ou "date".');
    }

    for (final task in sorted) {
      print(task);
    }
  }

  Future<void> _done(List<String> args) async {
    if (args.isEmpty) {
      throw InvalidCommandException('Usage: done <id>');
    }
    final id = await _resolveId(args[0]);
    await repository.markDone(id);
    print('Tâche $id marquée comme terminée.');
  }

  Future<void> _delete(List<String> args) async {
    if (args.isEmpty) {
      throw InvalidCommandException('Usage: delete <id>');
    }
    final id = await _resolveId(args[0]);
    await repository.delete(id);
    print('Tâche $id supprimée.');
  }

  /// Allows the user to pass either the full id or the short 8-character
  /// prefix printed by `list`.
  Future<String> _resolveId(String idOrPrefix) async {
    final tasks = await repository.getAll();
    final exact = tasks.where((t) => t.id == idOrPrefix);
    if (exact.isNotEmpty) return exact.first.id;

    final matches = tasks.where((t) => t.id.startsWith(idOrPrefix)).toList();
    if (matches.isEmpty) throw TaskNotFoundException(idOrPrefix);
    if (matches.length > 1) {
      throw InvalidCommandException(
        'L\'identifiant "$idOrPrefix" correspond à plusieurs tâches, précise-le davantage.',
      );
    }
    return matches.first.id;
  }

  void _printHelp() {
    print('''
Task Manager CLI — gestion de tâches en ligne de commande

Commandes:
  add "<titre>" <low|medium|high> [AAAA-MM-JJ] [--urgent] [--escalation=<heures>]
      Ajoute une tâche. --urgent crée une UrgentTask.
  list [--sort=priority|date]
      Liste toutes les tâches (tri par priorité par défaut).
  done <id>
      Marque une tâche comme terminée.
  delete <id>
      Supprime une tâche.
  help
      Affiche cette aide.

Exemples:
  dart run bin/main.dart add "Réviser Dart" high 2026-07-20
  dart run bin/main.dart add "Payer la facture" medium --urgent --escalation=12
  dart run bin/main.dart list --sort=date
  dart run bin/main.dart done a1b2c3d4
''');
  }
}
