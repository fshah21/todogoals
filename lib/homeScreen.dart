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
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];

  final _categoryController = TextEditingController();
  final _taskController = TextEditingController();

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        categories.add(Category(name: _categoryController.text));
      });
      _categoryController.clear();
    }
  }

  void _addTask(Category category) {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        category.tasks.add(Task(title: _taskController.text));
      });
      _taskController.clear();
    }
  }

  void _deleteTask(Category category, int index) {
    setState(() {
      category.tasks.removeAt(index);
    });
  }

  void _toggleTaskChecked(Category category, int index) {
    setState(() {
      category.tasks[index].isChecked = !category.tasks[index].isChecked;
    });
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
            // Add Category Section
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Add Category',
              ),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Add Category'),
            ),
            const SizedBox(height: 16),

            // Display Categories
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),

                          // Add Task Section
                          TextField(
                            controller: _taskController,
                            decoration: const InputDecoration(
                              labelText: 'Add Task',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _addTask(category),
                            child: const Text('Add Task'),
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
