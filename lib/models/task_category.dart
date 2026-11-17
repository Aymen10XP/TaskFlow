import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCategory {
  const TaskCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory TaskCategory.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => TaskCategory(
    id: document.id,
    name: document.data()?['name'] as String? ?? '',
  );
}
