import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define models for Task and Category
class Task {
  String title;
  bool isChecked;

  Task({required this.title, this.isChecked = false});
}

class Category {
  String name;
  List<Task> tasks;

  Category({required this.name, List<Task>? tasks}) : tasks = tasks ?? [];
}

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];

  final _categoryController = TextEditingController();
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories and tasks from Firestore when the screen is loaded
  }

  // Load categories and tasks from Firestore
  Future<void> _loadCategories() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        final categoriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('categories')
            .get();

        setState(() {
          categories = categoriesSnapshot.docs.map((doc) {
            final categoryData = doc.data();
            final tasksList = (categoryData['tasks'] as List<dynamic>).map((taskData) {
              return Task(title: taskData['title'], isChecked: taskData['isChecked']);
            }).toList();

            return Category(
              name: categoryData['name'],
              tasks: tasksList,
            );
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  // Save category and task to Firestore
  Future<void> _saveCategory(Category category) async {
    try {
      final categoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('categories')
          .doc(category.name);

      final tasks = category.tasks.map((task) => {
        'title': task.title,
        'isChecked': task.isChecked,
      }).toList();

      await categoryRef.set({
        'name': category.name,
        'tasks': tasks,
      });
    } catch (e) {
      print("Error saving category: $e");
    }
  }

  // Delete category from Firestore
  Future<void> _deleteCategory(Category category) async {
    try {
      final categoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('categories')
          .doc(category.name);

      await categoryRef.delete();

      setState(() {
        categories.remove(category); // Remove from UI after deletion
      });
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      final newCategory = Category(name: _categoryController.text);
      setState(() {
        categories.add(newCategory);
      });

      // Save the new category to Firestore
      _saveCategory(newCategory);

      _categoryController.clear();
    }
  }

  void _addTask(Category category) {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        category.tasks.add(Task(title: _taskController.text));
      });

      // Save the updated tasks to Firestore
      _saveCategory(category);

      _taskController.clear();
    }
  }

  void _deleteTask(Category category, int index) {
    setState(() {
      category.tasks.removeAt(index);
    });

    // Save the updated tasks to Firestore
    _saveCategory(category);
  }

  void _toggleTaskChecked(Category category, int index) {
    setState(() {
      category.tasks[index].isChecked = !category.tasks[index].isChecked;
    });

    // Save the updated tasks to Firestore
    _saveCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To Do List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Category Section (Inline)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Add Category',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display Categories
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name with delete button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(category.name, style: const TextStyle(fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Add Task Section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _taskController,
                                decoration: const InputDecoration(
                                  labelText: 'Add Task',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addTask(category),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Display Tasks
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: category.tasks.length,
                          itemBuilder: (context, taskIndex) {
                            final task = category.tasks[taskIndex];
                            return ListTile(
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isChecked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(category, taskIndex),
                              ),
                              leading: Checkbox(
                                value: task.isChecked,
                                onChanged: (value) => _toggleTaskChecked(category, taskIndex),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
