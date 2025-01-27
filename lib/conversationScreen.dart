import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationScreen extends StatefulWidget {
  final String roomId;
  final String userId;

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
  List<Map<String, dynamic>> messages = [];
  final ImagePicker _picker = ImagePicker();
  XFile? selectedImage;

  @override
  void initState() {
    super.initState();

    // Initialize socket connection
    socket = IO.io('https://todobackend-913436538919.asia-south1.run.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();

    socket.on('connect', (_) {
      String matchedWith = widget.roomId.split('-')[1];
      socket.emit('join-room', {'userId': widget.userId, 'matchedWith': matchedWith});
    });

    socket.on('message-history', (data) {
      if (mounted) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
        });
      }
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print("IN PICK IMAGE");
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile;
      });

      // Send image as base64 string
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print("BASE 64 DONE");

      socket.emit('send-message', {
        'roomId': widget.roomId,
        'message': null, // No text content
        'imagePath': base64Image,
        'messageType': 'image',
        'senderId': widget.userId,
      });

      setState(() {
        messages.add({'image_path': base64Image, 'sender_id': widget.userId});
        selectedImage = null; // Clear after sending
      });
    }
  }

  void sendMessage() {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      socket.emit('send-message', {
        'roomId': widget.roomId,
        'message': message,
        'messageType': "text",
        'senderId': widget.userId,
      });

      setState(() {
        messages.add({'message_content': message, 'sender_id': widget.userId});
      });

      messageController.clear();
    }
  }

  void _showFullImage(String base64Image) {
    print("IN SHOW FULL IMAGE");
    final Uint8List imageData = base64Decode(base64Image);

    showDialog(
      context: context,
      builder: (context) {
        Timer(const Duration(seconds: 10), () {
          Navigator.of(context).pop();
        });

        return AlertDialog(
          content: Image.memory(imageData),
        );
      },
    );
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
          // Chat messages list
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                print("MESSAGE $message");
                final senderId = message['sender_id'] ?? '';
                print("SENDER ID $senderId");
                final isSentByUser = senderId == widget.userId;
                print("IS SENT BY USER $isSentByUser");
                // print("MESSAGE PATH ${message['image_url']}");

                if (message['message_type'] == 'image') {
                  print("MESSAGE TYPE IS IMAGE");
                  return Align(
                    alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _showFullImage(message['image_url'] ?? ''),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
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
                          message['message_content'] ?? '',
                          style: TextStyle(
                            color: isSentByUser ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          // Input field and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    messageController.text.isEmpty ? Icons.image : Icons.send,
                  ),
                  onPressed: messageController.text.isEmpty ? _pickImage : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
