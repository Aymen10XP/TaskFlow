import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_category.dart';

class CategoryRepository {
  CategoryRepository({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories => _firestore
      .collection('users')
      .doc(userId)
      .collection('categories');

  Stream<List<TaskCategory>> watchCategories() => _categories
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TaskCategory.fromDocument).toList());

  Future<void> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _categories.add({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    final tasks = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks');
    final assigned = await tasks
        .where('categoryId', isEqualTo: categoryId)
        .get();
    for (var start = 0; start < assigned.docs.length; start += 450) {
      final batch = _firestore.batch();
      for (final task in assigned.docs.skip(start).take(450)) {
        batch.update(task.reference, {
          'categoryId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    await _categories.doc(categoryId).delete();
  }
}
