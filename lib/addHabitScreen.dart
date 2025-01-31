import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHabitScreen extends StatefulWidget {
  final String userId; // Accept userId as a parameter

  const AddHabitScreen({required this.userId});

  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  List<Map<String, dynamic>> goals = [];

  // Fetch goals and check mapping with user
  Future<void> fetchGoals() async {
  try {
    // Fetch all goals
    final goalsSnapshot =
        await FirebaseFirestore.instance.collection('goals').get();

    // Fetch user-goal mappings for the logged-in user
    final userGoalsSnapshot = await FirebaseFirestore.instance
        .collection('userGoals')
        .where('userId', isEqualTo: widget.userId)
        .get();

    // Create a map of goal IDs that the user has enrolled in
    final userGoalsMap = userGoalsSnapshot.docs.asMap().map(
        (key, doc) {
            final goalId = doc['goalId'];
            final status = doc.data().containsKey('status') ? doc['status'] : 'Not Enrolled';
            return MapEntry(goalId, status);
        },
    );


    print("USER GOALS MAP $userGoalsMap");

    // Update the goals list with status
    setState(() {
      goals = goalsSnapshot.docs.map((goalDoc) {
        final goalId = goalDoc.id;
        final goalName = goalDoc['name'];

        // Check if this goal is in the user's mappings
        final status = userGoalsMap[goalId] ?? 'Not Enrolled';
        print("STATUS $status");

        return {'id': goalId, 'name': goalName, 'status': status};
      }).toList();
    });
  } catch (e) {
    print('Error fetching goals: $e');
  }
}

  // Enroll a user to a goal
  Future<void> enrollUserToGoal(String goalId) async {
    try {
      print("IN ENROLL USER TO GOAL");
      // Add or update the mapping in Firestore with status "Enrolled"
      final userGoalCollection = FirebaseFirestore.instance.collection('userGoals');

      // Check if there's an existing mapping for this user and goal
      final existingMapping = await userGoalCollection
          .where('userId', isEqualTo: widget.userId)
          .where('goalId', isEqualTo: goalId)
          .get();

      if (existingMapping.docs.isEmpty) {
        print("EXISTING MAPPING");
        // Create a new mapping with status "Enrolled"
        await userGoalCollection.add({
          'userId': widget.userId,
          'goalId': goalId,
          'status': 'Enrolled',
        });
      } else {
        print("ELSE PART");
        // Update the existing mapping to set status to "Enrolled"
        await userGoalCollection
            .doc(existingMapping.docs.first.id)
            .update({'status': 'Enrolled'});
      }

      // Reload the goals after enrollment
      await fetchGoals();
    } catch (e) {
      print('Error enrolling user to goal: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGoals(); // Fetch goals when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Habit'),
        backgroundColor: Colors.deepPurple,
      ),
      body: goals.isEmpty
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return GoalCard(
                  goalName: goals[index]['name'] ?? 'Unnamed Goal',
                  status: goals[index]['status'] ?? 'Unknown',
                  onTap: () {
                    if (goals[index]['status'] == 'Enrolled' || goals[index]['status'] == 'Matched') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You are already enrolled!')),
                      );
                      return;
                    }

                    // Show enrollment dialog
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Enroll Now?'),
                          content: Text(
                              'Do you want to enroll in "${goals[index]['name']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close the dialog
                              },
                              child: Text('No'),
                            ),
                            TextButton(
                              onPressed: () async {
                                print("ON PRESSED YES");
                                Navigator.pop(context); // Close the dialog
                                print("POPING DONE");
                                print(goals[index]);
                                await enrollUserToGoal(goals[index]['id']);
                              },
                              child: Text('Yes'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

// Goal Card Widget
class GoalCard extends StatelessWidget {
  final String goalName;
  final String status;
  final VoidCallback onTap;

  const GoalCard({
    required this.goalName,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          goalName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == 'Not Enrolled' ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        onTap: onTap, // Trigger the onTap callback
      ),
    );
  }
}
