import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final repository = TaskRepository(userId: user.uid);
    return StreamBuilder<List<Task>>(
      stream: repository.watchTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DashboardMessage(
            icon: Icons.cloud_off_outlined,
            message: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final now = DateTime.now();
        final completed = tasks
            .where((task) => task.status == TaskStatus.done)
            .length;
        final overdue = tasks
            .where(
              (task) =>
                  task.status != TaskStatus.done &&
                  task.dueAt != null &&
                  task.dueAt!.isBefore(now),
            )
            .length;
        final upcoming = tasks
            .where(
              (task) =>
                  task.status != TaskStatus.done &&
                  task.dueAt != null &&
                  !task.dueAt!.isBefore(now),
            )
            .length;
        final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.tr('overview'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              user.displayName?.isNotEmpty == true
                  ? '${context.tr('account')}: ${user.displayName}'
                  : user.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  label: context.tr('total'),
                  value: tasks.length,
                  icon: Icons.task_alt,
                  color: Colors.indigo,
                ),
                _StatCard(
                  label: context.tr('completed'),
                  value: completed,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _StatCard(
                  label: context.tr('overdue'),
                  value: overdue,
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
                _StatCard(
                  label: context.tr('upcoming'),
                  value: upcoming,
                  icon: Icons.event_outlined,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('progress'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, value, _) => Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          const SizedBox(height: 10),
                          Text('${(value * 100).round()}%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: color),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    ),
  );
}
