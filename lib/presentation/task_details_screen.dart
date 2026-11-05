import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskDetailsArguments {
  const TaskDetailsArguments({required this.userId, required this.taskId});

  final String userId;
  final String taskId;
}

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({required this.arguments, super.key});

  static const routeName = '/task-details';
  final TaskDetailsArguments arguments;

  @override
  Widget build(BuildContext context) {
    final repository = TaskRepository(userId: arguments.userId);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('taskDetails'))),
      body: StreamBuilder<Task?>(
        stream: repository.watchTask(arguments.taskId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final task = snapshot.data;
          if (task == null) {
            return Center(child: Text(context.tr('noTasks')));
          }
          return _Details(task: task, repository: repository);
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.task, required this.repository});

  final Task task;
  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Hero(
            tag: 'task-${task.id}',
            child: Material(
              color: Colors.transparent,
              child: CircleAvatar(
                radius: 34,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  task.status == TaskStatus.done
                      ? Icons.check_rounded
                      : Icons.task_alt,
                  size: 34,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            task.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _InformationCard(
            icon: Icons.notes_outlined,
            label: context.tr('description'),
            value: task.description.isEmpty
                ? context.tr('notSet')
                : task.description,
          ),
          _InformationCard(
            icon: Icons.flag_outlined,
            label: context.tr('priority'),
            value: _priorityLabel(context, task.priority),
          ),
          _InformationCard(
            icon: Icons.pending_actions_outlined,
            label: context.tr('status'),
            value: _statusLabel(context, task.status),
          ),
          _InformationCard(
            icon: Icons.event_outlined,
            label: context.tr('dueDate'),
            value: task.dueAt == null
                ? context.tr('notSet')
                : DateFormat.yMMMMd(Localizations.localeOf(context).toString())
                      .add_jm()
                      .format(task.dueAt!),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final next = task.status == TaskStatus.done
                  ? TaskStatus.todo
                  : TaskStatus.done;
              await repository.setStatus(task, next);
            },
            icon: Icon(
              task.status == TaskStatus.done ? Icons.undo : Icons.check,
            ),
            label: Text(
              task.status == TaskStatus.done
                  ? context.tr('todo')
                  : context.tr('completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    ),
  );
}

String _priorityLabel(BuildContext context, TaskPriority priority) =>
    context.tr(priority.name);

String _statusLabel(BuildContext context, TaskStatus status) =>
    switch (status) {
      TaskStatus.todo => context.tr('todo'),
      TaskStatus.inProgress => context.tr('inProgress'),
      TaskStatus.done => context.tr('done'),
    };
