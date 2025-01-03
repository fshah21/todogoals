import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;  // Corrected import

class ConversationScreen extends StatefulWidget {
  final String roomId; // Receive the roomId
  final String userId;

  const ConversationScreen({required this.roomId, required this.userId, Key? key}) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late IO.Socket socket; // Socket instance
  TextEditingController messageController = TextEditingController();
  List<String> messages = []; // List to hold messages

  @override
  void initState() {
    super.initState();
    // Initialize socket connection
    socket = IO.io('https://todobackend-913436538919.asia-south1.run.app', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to socket');
      // Join the chat room
      socket.emit('join-room', {'roomId': widget.roomId});
    });

    // Listen for incoming messages
    socket.on('receive-message', (message) {
      setState(() {
        messages.add(message);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Clean up and close socket connection
    socket.disconnect();
  }

  void sendMessage() {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      socket.emit('send-message', {'roomId': widget.roomId, 'message': message, 'messageType': "text", "senderId": widget.userId});
      setState(() {
        messages.add(message);
      });
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Room"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
