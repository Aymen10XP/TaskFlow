import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/app_preferences.dart';
import '../repositories/task_repository.dart';
import '../services/auth_service.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final repository = TaskRepository(userId: user.uid);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => context.read<AppPreferences>().toggleTheme(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              try {
                await AuthService.instance.signOut();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(friendlyAuthError(error))),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, repository),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Column(
        children: [
          _AccountHeader(user: user),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: repository.watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.cloud_off_outlined,
                    message: friendlyAuthError(snapshot.error!),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return const _MessageState(
                    icon: Icons.checklist_outlined,
                    message: 'No tasks yet. Add one to get started.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskTile(
                      task: task,
                      repository: repository,
                      onEdit: () =>
                          _openEditor(context, repository, task: task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    TaskRepository repository, {
    Task? task,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TaskEditor(task: task, repository: repository),
  );
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim();
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoURL == null
            ? null
            : NetworkImage(user.photoURL!),
        child: user.photoURL == null
            ? Text(
                (name?.isNotEmpty ?? false)
                    ? name![0].toUpperCase()
                    : (user.email?.isNotEmpty ?? false)
                    ? user.email![0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(name?.isNotEmpty == true ? name! : 'Your account'),
      subtitle: Text(user.email ?? ''),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.repository,
    required this.onEdit,
  });

  final Task task;
  final TaskRepository repository;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    final dueText = task.dueAt == null
        ? null
        : 'Due ${DateFormat.yMMMd().add_jm().format(task.dueAt!)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: (value) => _perform(
            context,
            () => repository.setStatus(
              task,
              value == true ? TaskStatus.done : TaskStatus.todo,
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Theme.of(context).colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) Text(task.description),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_priorityLabel(task.priority)),
                ),
                if (dueText != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text(dueText),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: task.description.isNotEmpty || dueText != null,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              onEdit();
            } else if (action == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await _perform(context, () => repository.deleteTask(task.id));
    }
  }
}

Future<void> _perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyAuthError(error))));
    }
  }
}

String _priorityLabel(TaskPriority priority) => switch (priority) {
  TaskPriority.low => 'Low',
  TaskPriority.normal => 'Normal',
  TaskPriority.high => 'High',
};

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.repository, this.task});

  final TaskRepository repository;
  final Task? task;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.task?.title);
  late final _descriptionController = TextEditingController(
    text: widget.task?.description,
  );
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.normal;
  late DateTime? _dueAt = widget.task?.dueAt;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final task = widget.task;
      if (task == null) {
        await widget.repository.createTask(
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueAt: _dueAt,
        );
      } else {
        await widget.repository.updateTask(
          task: task,
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueAt: _dueAt,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyAuthError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null) setState(() => _dueAt = date);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.task == null ? 'Create task' : 'Edit task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TaskStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null) setState(() => _status = status);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(_priorityLabel(priority)),
                    ),
                  )
                  .toList(),
              onChanged: (priority) {
                if (priority != null) setState(() => _priority = priority);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _dueAt == null
                    ? 'Add due date'
                    : 'Due ${DateFormat.yMMMd().format(_dueAt!)}',
              ),
              trailing: _dueAt == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.close),
                    ),
              onTap: _chooseDueDate,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.task == null ? 'Create task' : 'Save changes'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.todo => 'To do',
  TaskStatus.inProgress => 'In progress',
  TaskStatus.done => 'Done',
};
