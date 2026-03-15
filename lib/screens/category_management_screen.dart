import 'package:flutter/material.dart';
import '../models/category_registry.dart';

/// Screen for managing built-in and user-defined categories.
///
/// NOTE: This is a placeholder implementation. Full UI will be implemented
/// as part of the SlipDetailScreen learning UX task.
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Built-in Categories', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final cat in kBuiltInCategories)
            ListTile(
              leading: Text(cat.emoji),
              title: Text(cat.label),
            ),
        ],
      ),
    );
  }
}
