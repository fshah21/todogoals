import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationScreen extends StatefulWidget {
  final String roomId;
  final String userId; // Add userId to identify the current user

  const ConversationScreen({
    required this.roomId,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late IO.Socket socket;
  TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = []; // List to hold messages (message & senderId)

  @override
  void initState() {
    super.initState();

    // Initialize socket connection
    socket = IO.io('https://todobackend-913436538919.asia-south1.run.app', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to socket');
      String matchedWith = widget.roomId.split('-')[1];
      // Join the chat room
      socket.emit('join-room', {
        'userId': widget.userId,
        'matchedWith': matchedWith
      });
    });

    socket.on('message-history', (data) {
      print("Message history received: $data");
      setState(() {
        // Populate messages list with the fetched history
        messages = List<Map<String, dynamic>>.from(data['messages']);
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
    print("IN SEND MESSAGE");
    String message = messageController.text.trim();
    print("MESSAGE $message");
    if (message.isNotEmpty) {
      socket.emit('send-message', {
        'roomId': widget.roomId,
        'message': message,
        'messageType': "text",
        'senderId': widget.userId,
      });

      // Add the sent message to the list
      setState(() {
        messages.add({'message_content': message, 'sender_id': widget.userId});
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
                final message = messages[index]['message_content'];
                final senderId = messages[index]['sender_id'];
                final isSentByUser = senderId == widget.userId; // Check if the message is sent by the user

                return Align(
                  alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSentByUser ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isSentByUser ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
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