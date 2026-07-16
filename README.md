# Task Manager CLI

Application en ligne de commande de gestion de tâches, écrite en **Dart pur**
(sans Flutter), réalisée pour le projet de certification "Projet Dart —
Application CLI de gestion de tâches".

## Fonctionnalités

- Ajouter une tâche (titre, priorité `low`/`medium`/`high`, date limite optionnelle)
- Lister toutes les tâches, triées par priorité ou par date
- Marquer une tâche comme terminée
- Supprimer une tâche
- Persistance des données dans un fichier JSON local (`tasks.json`)

## Exigences techniques couvertes

| Exigence | Où |
|---|---|
| Classes abstraites + héritage | `Task` (abstraite) → `UrgentTask`, `StandardTask` dans `lib/src/task.dart` |
| Interface | `Repository<T>` dans `lib/src/repository.dart`, implémentée par `JsonTaskRepository` |
| Génériques | `abstract class Repository<T>` |
| Exceptions personnalisées | `lib/src/exceptions.dart` (`TaskNotFoundException`, `InvalidTaskDataException`, `InvalidCommandException`) |
| ≥ 5 tests unitaires | `test/task_repository_test.dart` (11 tests) avec le package `test` |

## Prérequis

- [Dart SDK](https://dart.dev/get-dart) ≥ 3.0.0 (aucune dépendance Flutter n'est nécessaire)

Vérifier l'installation :

```bash
dart --version
```

## Installation

```bash
git clone https://github.com/<username>/<repo-name>.git
cd <repo-name>
dart pub get
```

## Lancer l'application

Toutes les commandes se lancent avec `dart run bin/main.dart <commande> [arguments]`.
Les données sont sauvegardées dans `tasks.json` à la racine du projet.

### Ajouter une tâche

```bash
dart run bin/main.dart add "Réviser Dart" high 2026-07-20
dart run bin/main.dart add "Payer la facture" medium --urgent --escalation=12
```

- 1er argument : titre (entre guillemets si espaces)
- 2e argument : priorité (`low`, `medium`, `high`)
- 3e argument optionnel : date limite au format `AAAA-MM-JJ`
- `--urgent` : crée une `UrgentTask` (affiche un avertissement ⚠ quand
  l'échéance approche)
- `--escalation=<heures>` : nombre d'heures avant l'échéance à partir
  duquel une `UrgentTask` est considérée comme escaladée (défaut : 24)

### Lister les tâches

```bash
dart run bin/main.dart list
dart run bin/main.dart list --sort=date
dart run bin/main.dart list --sort=priority
```

### Marquer une tâche comme terminée

```bash
dart run bin/main.dart done <id>
```

L'`<id>` affiché par `list` est tronqué à 8 caractères ; il suffit de
fournir ce préfixe (ou l'id complet).

### Supprimer une tâche

```bash
dart run bin/main.dart delete <id>
```

### Aide

```bash
dart run bin/main.dart help
```

## Lancer les tests

```bash
dart test
```

Cela exécute `test/task_repository_test.dart`, qui couvre :
- l'ajout, la lecture, la mise à jour (`markDone`) et la suppression de tâches,
- la levée de `TaskNotFoundException` sur un id inconnu,
- la levée de `InvalidTaskDataException` sur une priorité invalide, un
  fichier JSON corrompu, et un titre vide,
- la sérialisation/désérialisation JSON d'une `UrgentTask` (champ additionnel
  `escalationHours` inclus).

Les tests utilisent un dossier temporaire (`Directory.systemTemp`) pour ne
jamais toucher au fichier `tasks.json` réel du projet.

## Structure du projet

```
bin/
  main.dart              # point d'entrée du CLI
lib/src/
  task.dart              # Task (abstraite), StandardTask, UrgentTask
  priority.dart          # enum Priority + parsing/tri
  repository.dart        # interface générique Repository<T>
  task_repository.dart   # JsonTaskRepository implements Repository<Task>
  cli.dart               # parsing des arguments et commandes
test/
  task_repository_test.dart
```

## Difficultés rencontrées / choix d'implémentation

- Le format de fichier `tasks.json` inclut un champ `type` (`standard` |
  `urgent`) pour permettre à `Task.fromJson` de reconstruire la bonne
  sous-classe au chargement.
- Les ids sont générés localement (timestamp en base36 + suffixe
  aléatoire) pour éviter une dépendance externe au package `uuid`.
- `Repository<T>` reste volontairement générique (pas lié à `Task`) pour
  bien illustrer l'usage des génériques, tandis que `JsonTaskRepository`
  l'implémente concrètement pour `Task`.
