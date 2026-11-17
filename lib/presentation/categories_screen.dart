import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/task_category.dart';
import '../repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({required this.user, super.key});

  final User user;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final _repository = CategoryRepository(userId: widget.user.uid);

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('newCategory')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(labelText: context.tr('categoryName')),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.tr('add')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await _repository.createCategory(name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
    }
  }

  Future<void> _deleteCategory(TaskCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteCategory')),
        content: Text(
          context.tr('deleteCategoryConfirmation', {'name': category.name}),
        ),
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
    if (confirmed == true) await _repository.deleteCategory(category.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('categories'))),
    body: StreamBuilder<List<TaskCategory>>(
      stream: _repository.watchCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(context.tr('errorGeneric')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return Center(child: Text(context.tr('noCategories')));
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final category = snapshot.data![index];
            return ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(category.name),
              trailing: IconButton(
                tooltip: context.tr('delete'),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteCategory(category),
              ),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addCategory,
      icon: const Icon(Icons.add),
      label: Text(context.tr('newCategory')),
    ),
  );
}
