import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'addHabitScreen.dart';
import 'conversationScreen.dart';

class ChatScreen extends StatelessWidget {
  final String userId; // Accept userId

  const ChatScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("IN THE WIDGET");
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Chats (User: $userId)'), // Display userId
        backgroundColor: Color(0xFF5271FF),
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
              // return FutureBuilder<DocumentSnapshot>(
              //   future: FirebaseFirestore.instance
              //       .collection('goals')
              //       .doc(goalId)
              //       .get(),
              //   builder: (context, goalSnapshot) {
              //     if (goalSnapshot.connectionState == ConnectionState.waiting) {
              //       return const SizedBox.shrink();
              //     }

              //     if (!goalSnapshot.hasData || !goalSnapshot.data!.exists) {
              //       return const SizedBox.shrink();
              //     }

              //     final goalName = goalSnapshot.data!['name'];

              //     // If matchedWith exists, fetch user details
              //     if (matchedWith != null) {
              //       return FutureBuilder<DocumentSnapshot>(
              //         future: FirebaseFirestore.instance
              //             .collection('users')
              //             .doc(matchedWith)
              //             .get(),
              //         builder: (context, userSnapshot) {
              //           if (userSnapshot.connectionState == ConnectionState.waiting) {
              //             return const SizedBox.shrink(); // Optionally, show loading indicator here
              //           }

              //           if (userSnapshot.hasError) {
              //             // Handle any error that occurs while fetching the user document
              //             print("Error fetching user: ${userSnapshot.error}");
              //             return const SizedBox.shrink();
              //           }

              //           if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              //             // If no user data is found, handle the empty state
              //             print("User document does not exist.");
              //             return const SizedBox.shrink();
              //           }

              //           final matchedUser = userSnapshot.data!.data() as Map<String, dynamic>;
              //           final firstName = matchedUser['firstName'] ?? 'Unknown';
              //           final lastName = matchedUser['lastName'] ?? 'User';

              //           final roomId = [userId, matchedWith]..sort();
              //           final roomIdString = roomId.join("-");

              //           FirebaseFirestore.instance.collection('chats').doc(roomIdString).get().then((roomDoc) {
              //             builder: (context, chatSnapshot) {
              //             if (chatSnapshot.connectionState == ConnectionState.waiting) {
              //               return const SizedBox.shrink();
              //             }

              //             int userStreak = 0;
              //             int buddyStreak = 0;

              //             if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
              //               final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
              //               final scores = chatData.containsKey('scores') ? chatData['scores'] as Map<String, dynamic> : {};
              //               userStreak = scores.containsKey(userId) ? scores[userId]['streak'] ?? 0 : 0;
              //               buddyStreak = scores.containsKey(matchedWith) ? scores[matchedWith]['streak'] ?? 0 : 0;
              //             } else {
              //               // If chat room doesn't exist, create it
              //               FirebaseFirestore.instance.collection('chats').doc(roomIdString).set({
              //                 'userIds': [userId, matchedWith],
              //                 'createdAt': FieldValue.serverTimestamp(),
              //                 'lastMessage': null,
              //                 'scores': {},
              //               });
              //             }

              //             return ChatCard(
              //               title: "$goalName - ($firstName $lastName)",
              //               description: status ?? "No status",
              //               roomId: roomIdString,
              //               userId: userId,
              //               userStreak: userStreak,
              //               buddyStreak: buddyStreak,
              //             );
              //           };
              //         });
              //     });
              //     } else {
              //       print("MATCHED WITH IS NULL OR EMPTY");
              //       return const SizedBox.shrink(); // No matched user, do nothing
              //     }

              //     // If no matchedWith, display just the goal name
              //     return ChatCard(
              //       title: "**$goalName**",
              //       description: status ?? "No status",
              //       roomId: "roomId",
              //       userId: "userId",
              //       userStreak: 0,
              //       buddyStreak: 0
              //     );
              //   },
              // );
              return FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance.collection('goals').doc(goalId).get(),
  builder: (context, goalSnapshot) {
    if (goalSnapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }

    if (!goalSnapshot.hasData || !goalSnapshot.data!.exists) {
      return const SizedBox.shrink();
    }

    final goalName = goalSnapshot.data!['name'];

    if (matchedWith != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(matchedWith).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            print("Error fetching user or user document does not exist.");
            return const SizedBox.shrink();
          }

          final matchedUser = userSnapshot.data!.data() as Map<String, dynamic>;
          final firstName = matchedUser['firstName'] ?? 'Unknown';
          final lastName = matchedUser['lastName'] ?? 'User';

          final roomId = [userId, matchedWith]..sort();
          final roomIdString = roomId.join("-");

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('chats').doc(roomIdString).get(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              int userStreak = 0;
              int buddyStreak = 0;

              if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
                final scores = chatData.containsKey('scores') ? chatData['scores'] as Map<String, dynamic> : {};
                userStreak = scores.containsKey(userId) ? (scores[userId]['streak'] ?? 0) : 0;
                buddyStreak = scores.containsKey(matchedWith) ? (scores[matchedWith]['streak'] ?? 0) : 0;
              } else {
                // If chat room doesn't exist, create it
                FirebaseFirestore.instance.collection('chats').doc(roomIdString).set({
                  'userIds': [userId, matchedWith],
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastMessage': null,
                  'scores': {},
                });
              }

              return ChatCard(
                title: "$goalName - ($firstName $lastName)",
                description: status ?? "No status",
                roomId: roomIdString,
                userId: userId,
                userStreak: userStreak,
                buddyStreak: buddyStreak,
              );
            },
          );
        },
      );
    } else {
      print("MATCHED WITH IS NULL OR EMPTY");
      return const SizedBox.shrink();
    }
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
  final String roomId; // Add roomId to pass
  final String userId;
  final int userStreak;
  final int buddyStreak;

  const ChatCard({
    required this.title,
    required this.description,
    required this.roomId, // Add roomId parameter
    required this.userId,
    required this.userStreak,
    required this.buddyStreak,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text("You", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("$userStreak", style: const TextStyle(fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Buddy", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("$buddyStreak", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Navigate to the conversation screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationScreen(roomId: roomId, userId: userId),
            ),
          );
        },
      ),
    );
  }
}