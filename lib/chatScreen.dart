import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'addHabitScreen.dart';

class ChatScreen extends StatelessWidget {
  final String userId; // Accept userId

  const ChatScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Chats (User: $userId)'), // Display userId
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<QuerySnapshot>(
        // Fetch user goals from Firestore where the userId matches
        future: FirebaseFirestore.instance
            .collection('userGoals')
            .where('userId', isEqualTo: userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No goals found.'));
          }

          // Fetch goal data and display the user goals
          final userGoals = snapshot.data!.docs;

          return ListView.builder(
            itemCount: userGoals.length,
            itemBuilder: (context, index) {
              final goalDoc = userGoals[index];
              final goalId = goalDoc['goalId'];
              final data = goalDoc.data() as Map<String, dynamic>;
              final matchedWith = data.containsKey('matchedWith') ? data['matchedWith'] : null;
              final status = data.containsKey('status') ? data['status'] : null;

              // Fetch goal name from 'goals' collection based on goalId
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('goals')
                    .doc(goalId)
                    .get(),
                builder: (context, goalSnapshot) {
                  if (goalSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (!goalSnapshot.hasData || !goalSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final goalName = goalSnapshot.data!['name'];

                  // If matchedWith exists, fetch user details
                  if (matchedWith != null) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(matchedWith)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final matchedUser = userSnapshot.data!.data() as Map<String, dynamic>;
                        final firstName = matchedUser['firstName'] ?? 'Unknown';
                        final lastName = matchedUser['lastName'] ?? 'User';

                        return ChatCard(
                          title: "$goalName - ($firstName $lastName)",
                          description: status ?? "No status",
                        );
                      },
                    );
                  }

                  // If no matchedWith, display just the goal name
                  return ChatCard(
                    title: "**$goalName**",
                    description: status ?? "No status",
                  );
                },
              );
            },
          );
        },
      ),
      // Persistent Button at the Bottom
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add Habit Button Action
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHabitScreen(userId: userId)),
          );
        },
        label: const Text("Add Habit"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Chat Card Widget
class ChatCard extends StatelessWidget {
  final String title;
  final String description;

  const ChatCard({
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Navigate to a detailed chat screen (optional)
        },
      ),
    );
  }
}
