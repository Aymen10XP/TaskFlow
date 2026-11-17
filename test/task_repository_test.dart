import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';
import 'package:taskflow/repositories/task_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository repository;

  CollectionReference<Map<String, dynamic>> tasksFor(String uid) =>
      firestore.collection('users').doc(uid).collection('tasks');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = TaskRepository(userId: 'alice', firestore: firestore);
  });

  test('createTask trims text and writes the expected task fields', () async {
    final dueAt = DateTime(2026, 12, 1, 9);

    await repository.createTask(
      title: '  Plan release  ',
      description: '  Prepare the build  ',
      status: TaskStatus.done,
      priority: TaskPriority.high,
      dueAt: dueAt,
    );

    final snapshot = await tasksFor('alice').get();
    expect(snapshot.docs, hasLength(1));
    final task = Task.fromDocument(snapshot.docs.single);
    expect(task.title, 'Plan release');
    expect(task.description, 'Prepare the build');
    expect(task.status, TaskStatus.done);
    expect(task.priority, TaskPriority.high);
    expect(task.dueAt, dueAt);
    expect(snapshot.docs.single.data()['createdAt'], isA<Timestamp>());
    expect(snapshot.docs.single.data()['updatedAt'], isA<Timestamp>());
    expect(snapshot.docs.single.data()['completedAt'], isA<Timestamp>());
  });

  test('watchTasks returns tasks newest first', () async {
    final tasks = tasksFor('alice');
    await tasks
        .doc('older')
        .set(_taskData(title: 'Older task', createdAt: DateTime(2026, 1, 1)));
    await tasks
        .doc('newer')
        .set(_taskData(title: 'Newer task', createdAt: DateTime(2026, 2, 1)));

    final result = await repository.watchTasks().first;

    expect(result.map((task) => task.title), ['Newer task', 'Older task']);
  });

  test('updateTask and setStatus update completion metadata', () async {
    final ref = tasksFor('alice').doc('task-1');
    await ref.set(_taskData(title: 'Draft', createdAt: DateTime(2026, 1)));
    final original = Task.fromDocument(await ref.get());

    await repository.updateTask(
      task: original,
      title: '  Ship feature  ',
      description: '  Ready to release  ',
      status: TaskStatus.done,
      priority: TaskPriority.high,
      dueAt: DateTime(2026, 3, 15),
    );

    var updated = (await ref.get()).data()!;
    expect(updated['title'], 'Ship feature');
    expect(updated['description'], 'Ready to release');
    expect(updated['status'], 'done');
    expect(updated['priority'], 'high');
    expect(updated['dueAt'], Timestamp.fromDate(DateTime(2026, 3, 15)));
    expect(updated['completedAt'], isA<Timestamp>());

    await repository.setStatus(
      Task.fromDocument(await ref.get()),
      TaskStatus.todo,
    );

    updated = (await ref.get()).data()!;
    expect(updated['status'], 'todo');
    expect(updated['completedAt'], isNull);
    expect(updated['updatedAt'], isA<Timestamp>());
  });

  test('deleteTask removes only the selected user task', () async {
    await tasksFor('alice')
        .doc('remove-me')
        .set(_taskData(title: 'Remove me', createdAt: DateTime(2026, 1)));
    await tasksFor('alice')
        .doc('keep-me')
        .set(_taskData(title: 'Keep me', createdAt: DateTime(2026, 2)));

    await repository.deleteTask('remove-me');

    expect((await tasksFor('alice').doc('remove-me').get()).exists, isFalse);
    expect((await tasksFor('alice').doc('keep-me').get()).exists, isTrue);
  });

  test('repository writes are scoped to its configured user', () async {
    final bobRepository = TaskRepository(userId: 'bob', firestore: firestore);

    await repository.createTask(
      title: 'Alice task',
      description: '',
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
    );
    await bobRepository.createTask(
      title: 'Bob task',
      description: '',
      status: TaskStatus.todo,
      priority: TaskPriority.normal,
    );

    expect((await tasksFor('alice').get()).docs, hasLength(1));
    expect((await tasksFor('bob').get()).docs, hasLength(1));
    expect((await tasksFor('alice').get()).docs.single['title'], 'Alice task');
    expect((await tasksFor('bob').get()).docs.single['title'], 'Bob task');
  });
}

Map<String, Object?> _taskData({
  required String title,
  required DateTime createdAt,
}) => {
  'title': title,
  'description': '',
  'status': 'todo',
  'priority': 'normal',
  'dueAt': null,
  'createdAt': Timestamp.fromDate(createdAt),
  'updatedAt': Timestamp.fromDate(createdAt),
  'completedAt': null,
};
