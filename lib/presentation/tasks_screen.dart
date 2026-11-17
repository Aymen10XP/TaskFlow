import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_category.dart';
import '../repositories/category_repository.dart';
import '../repositories/task_repository.dart';
import '../providers/app_preferences.dart';
import '../services/reminder_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';
import 'task_details_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({required this.user, super.key});

  final User user;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  TaskPriority? _priorityFilter;
  String? _categoryFilter;
  String _dueFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = TaskRepository(userId: widget.user.uid);
    final categoryRepository = CategoryRepository(userId: widget.user.uid);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('searchTasks'),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.tr('clearSearch'),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                DropdownButton<TaskPriority?>(
                  value: _priorityFilter,
                  hint: Text(context.tr('priority')),
                  items: [
                    DropdownMenuItem<TaskPriority?>(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...TaskPriority.values.map(
                      (p) => DropdownMenuItem<TaskPriority?>(
                        value: p,
                        child: Text(_priorityLabel(context, p)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _priorityFilter = value),
                ),
                DropdownButton<String>(
                  value: _dueFilter,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(context.tr('allDates')),
                    ),
                    DropdownMenuItem(
                      value: 'upcoming',
                      child: Text(context.tr('upcoming')),
                    ),
                    DropdownMenuItem(
                      value: 'overdue',
                      child: Text(context.tr('overdue')),
                    ),
                    DropdownMenuItem(
                      value: 'none',
                      child: Text(context.tr('noDueDate')),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _dueFilter = value ?? 'all'),
                ),
                StreamBuilder<List<TaskCategory>>(
                  stream: categoryRepository.watchCategories(),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? const <TaskCategory>[];
                    final selected = list.any((c) => c.id == _categoryFilter)
                        ? _categoryFilter
                        : null;
                    return DropdownButton<String?>(
                      value: selected,
                      hint: Text(context.tr('category')),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(context.tr('allCategories')),
                        ),
                        ...list.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _categoryFilter = value),
                    );
                  },
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: context.tr('todo')),
              Tab(text: context.tr('inProgress')),
              Tab(text: context.tr('done')),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<Task>>(
                  stream: repository.watchTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _MessageState(
                        icon: Icons.cloud_off_outlined,
                        message: context.tr(authErrorKey(snapshot.error!)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = snapshot.data!;
                    return TabBarView(
                      children: TaskStatus.values
                          .map(
                            (status) => _TaskList(
                              tasks: tasks.where((task) {
                                if (task.status != status) return false;
                                if (_query.isNotEmpty &&
                                    !task.title.toLowerCase().contains(
                                      _query,
                                    )) {
                                  return false;
                                }
                                if (_priorityFilter != null &&
                                    task.priority != _priorityFilter) {
                                  return false;
                                }
                                if (_categoryFilter != null &&
                                    task.categoryId != _categoryFilter) {
                                  return false;
                                }
                                final now = DateTime.now();
                                if (_dueFilter == 'upcoming' &&
                                    (task.dueAt == null ||
                                        task.dueAt!.isBefore(now))) {
                                  return false;
                                }
                                if (_dueFilter == 'overdue' &&
                                    (task.dueAt == null ||
                                        !task.dueAt!.isBefore(now) ||
                                        task.status == TaskStatus.done)) {
                                  return false;
                                }
                                if (_dueFilter == 'none' &&
                                    task.dueAt != null) {
                                  return false;
                                }
                                return true;
                              }).toList(),
                              repository: repository,
                              userId: widget.user.uid,
                              onEdit: (task) =>
                                  _openEditor(context, repository, task: task),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                PositionedDirectional(
                  end: 18,
                  bottom: 18,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openEditor(context, repository),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('newTask')),
                  ),
                ),
              ],
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

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.tasks,
    required this.repository,
    required this.userId,
    required this.onEdit,
  });

  final List<Task> tasks;
  final TaskRepository repository;
  final String userId;
  final ValueChanged<Task> onEdit;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _MessageState(
        icon: Icons.checklist_outlined,
        message: context.tr('noTasks'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskTile(
          task: task,
          repository: repository,
          onEdit: () => onEdit(task),
          onOpen: () => Navigator.pushNamed(
            context,
            TaskDetailsScreen.routeName,
            arguments: TaskDetailsArguments(userId: userId, taskId: task.id),
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.repository,
    required this.onEdit,
    required this.onOpen,
  });

  final Task task;
  final TaskRepository repository;
  final VoidCallback onEdit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    final dueText = task.dueAt == null
        ? null
        : context.tr('dueAt', {
            'date': DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .add_jm()
                .format(task.dueAt!),
          });
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onOpen,
        leading: Hero(
          tag: 'task-${task.id}',
          child: Material(
            color: Colors.transparent,
            child: Checkbox(
              value: done,
              onChanged: (value) {
                final status = value == true
                    ? TaskStatus.done
                    : TaskStatus.todo;
                final enabled = context
                    .read<AppPreferences>()
                    .notificationsEnabled;
                final strings = AppStrings.of(context);
                final messenger = ScaffoldMessenger.of(context);
                _perform(context, () async {
                  await repository.setStatus(task, status);
                  await _syncReminder(
                    Task(
                      id: task.id,
                      title: task.title,
                      description: task.description,
                      status: status,
                      priority: task.priority,
                      createdAt: task.createdAt,
                      dueAt: task.dueAt,
                      categoryId: task.categoryId,
                      reminderAt: task.reminderAt,
                    ),
                    repository.userId,
                    notificationsEnabled: enabled,
                    reminderTitle: strings.get('taskReminder'),
                    body: strings.get('reminderBody', {'title': task.title}),
                    errorMessage: strings.get('reminderNotScheduled'),
                    messenger: messenger,
                  );
                });
              },
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
                  label: Text(_priorityLabel(context, task.priority)),
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
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(context.tr('edit'))),
            PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteTask')),
        content: Text(context.tr('deleteConfirmation', {'title': task.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await _perform(context, () async {
        await repository.deleteTask(task.id);
        await ReminderService.instance.cancelTaskReminder(
          userId: repository.userId,
          taskId: task.id,
        );
      });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(authErrorKey(error)))));
    }
  }
}

Future<void> _syncReminder(
  Task task,
  String userId, {
  required bool notificationsEnabled,
  required String reminderTitle,
  required String body,
  required String errorMessage,
  required ScaffoldMessengerState messenger,
}) async {
  final reminderAt = task.reminderAt;
  if (!notificationsEnabled ||
      task.status == TaskStatus.done ||
      reminderAt == null) {
    await ReminderService.instance.cancelTaskReminder(
      userId: userId,
      taskId: task.id,
    );
    return;
  }
  final scheduled = await ReminderService.instance.scheduleTaskReminder(
    userId: userId,
    taskId: task.id,
    title: reminderTitle,
    body: body,
    reminderAt: reminderAt,
  );
  if (!scheduled) {
    messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}

String _priorityLabel(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.low => context.tr('low'),
      TaskPriority.normal => context.tr('normal'),
      TaskPriority.high => context.tr('high'),
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
  late DateTime? _reminderAt = widget.task?.reminderAt;
  late String? _categoryId = widget.task?.categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notificationsEnabled = context
        .read<AppPreferences>()
        .notificationsEnabled;
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reminderFailureMessage = strings.get('reminderNotScheduled');
    setState(() => _saving = true);
    try {
      final task = widget.task;
      final taskId = task == null
          ? await widget.repository.createTask(
              title: _titleController.text,
              description: _descriptionController.text,
              status: _status,
              priority: _priority,
              dueAt: _dueAt,
              categoryId: _categoryId,
              reminderAt: _reminderAt,
            )
          : task.id;
      if (task != null) {
        await widget.repository.updateTask(
          task: task,
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueAt: _dueAt,
          categoryId: _categoryId,
          reminderAt: _reminderAt,
        );
      }
      var reminderScheduled = true;
      if (_reminderAt != null &&
          _status != TaskStatus.done &&
          notificationsEnabled) {
        try {
          reminderScheduled = await ReminderService.instance
              .scheduleTaskReminder(
                userId: widget.repository.userId,
                taskId: taskId,
                title: strings.get('taskReminder'),
                body: strings.get('reminderBody', {
                  'title': _titleController.text.trim(),
                }),
                reminderAt: _reminderAt!,
              );
        } catch (_) {
          reminderScheduled = false;
        }
      } else {
        await ReminderService.instance.cancelTaskReminder(
          userId: widget.repository.userId,
          taskId: taskId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        if (_reminderAt != null && !reminderScheduled) {
          messenger.showSnackBar(
            SnackBar(content: Text(reminderFailureMessage)),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(authErrorKey(error)))),
        );
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

  Future<void> _chooseReminder() async {
    final now = DateTime.now();
    final defaultReminder = now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _dueAt ?? defaultReminder,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt == null
          ? TimeOfDay.fromDateTime(defaultReminder)
          : TimeOfDay.fromDateTime(_reminderAt!),
    );
    if (time == null) return;
    setState(
      () => _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
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
              context.tr(widget.task == null ? 'createTask' : 'editTask'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: context.tr('taskTitle'),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.tr('enterTitle')
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('description'),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: context.tr('status'),
                border: OutlineInputBorder(),
              ),
              items: TaskStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(context, status)),
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
              decoration: InputDecoration(
                labelText: context.tr('priority'),
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(_priorityLabel(context, priority)),
                    ),
                  )
                  .toList(),
              onChanged: (priority) {
                if (priority != null) setState(() => _priority = priority);
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<TaskCategory>>(
              stream: CategoryRepository(userId: widget.repository.userId)
                  .watchCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <TaskCategory>[];
                final selected = categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null;
                return DropdownButtonFormField<String?>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: context.tr('category'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.tr('noCategory')),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _dueAt == null
                    ? context.tr('addDueDate')
                    : context.tr('dueAt', {
                        'date': DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(_dueAt!),
                      }),
              ),
              trailing: _dueAt == null
                  ? null
                  : IconButton(
                      tooltip: context.tr('clearDueDate'),
                      onPressed: () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.close),
                    ),
              onTap: _chooseDueDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(
                _reminderAt == null
                    ? context.tr('setReminder')
                    : context.tr('reminderAt', {
                        'date': DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).add_jm().format(_reminderAt!),
                      }),
              ),
              trailing: _reminderAt == null
                  ? null
                  : IconButton(
                      tooltip: context.tr('clearReminder'),
                      onPressed: () => setState(() => _reminderAt = null),
                      icon: const Icon(Icons.close),
                    ),
              onTap: _chooseReminder,
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
                  : Text(
                      context.tr(
                        widget.task == null ? 'createTask' : 'saveChanges',
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _statusLabel(BuildContext context, TaskStatus status) =>
    switch (status) {
      TaskStatus.todo => context.tr('todo'),
      TaskStatus.inProgress => context.tr('inProgress'),
      TaskStatus.done => context.tr('done'),
    };
