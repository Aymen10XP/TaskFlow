import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskRepository {
  TaskRepository({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('users').doc(userId).collection('tasks');

  Stream<List<Task>> watchTasks() => _tasks
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Task.fromDocument).toList());

  Stream<Task?> watchTask(String taskId) => _tasks
      .doc(taskId)
      .snapshots()
      .map((snapshot) => snapshot.exists ? Task.fromDocument(snapshot) : null);

  Future<String> createTask({
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueAt,
    String? categoryId,
    DateTime? reminderAt,
  }) async {
    final now = FieldValue.serverTimestamp();
    final reference = await _tasks.add({
      'title': title.trim(),
      'description': description.trim(),
      'status': status.name,
      'priority': priority.name,
      'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
      'categoryId': categoryId,
      'reminderAt': reminderAt == null ? null : Timestamp.fromDate(reminderAt),
      'createdAt': now,
      'updatedAt': now,
      'completedAt': status == TaskStatus.done ? now : null,
    });
    return reference.id;
  }

  Future<void> updateTask({
    required Task task,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueAt,
    String? categoryId,
    DateTime? reminderAt,
  }) async {
    await _tasks.doc(task.id).update({
      'title': title.trim(),
      'description': description.trim(),
      'status': status.name,
      'priority': priority.name,
      'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
      'categoryId': categoryId,
      'reminderAt': reminderAt == null ? null : Timestamp.fromDate(reminderAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': status == TaskStatus.done
          ? FieldValue.serverTimestamp()
          : null,
    });
  }

  Future<void> setStatus(Task task, TaskStatus status) =>
      _tasks.doc(task.id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': status == TaskStatus.done
            ? FieldValue.serverTimestamp()
            : null,
      });

  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();
}
