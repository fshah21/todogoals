import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

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

    socket.on('receive-message', (data) {
      print("DATA $data");
      if (mounted) {
        if(data['message_type'] == "image") {
          setState(() {
            messages.add({'message_type': 'image', 'image_url': data['image_url'], 'sender_id': data['sender_id']});
            selectedImage = null; // Clear after sending
          });
        } else {
          setState(() {
            messages.add({'message_content': data['message_content'], 'sender_id': data['sender_id']});
          });
        }
        // setState(() {
        //   messages 
        // });
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

      messageController.clear();
    }
  }

  void _showFullImage(String imageUrl) {
    print("IN SHOW FULL IMAGE");
    print("IMAGE URL: $imageUrl");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black, // Set background to black for better viewing
        insetPadding: EdgeInsets.zero, // Make the image full screen
        child: GestureDetector(
          onTap: () => Navigator.pop(context), // Close on tap
          child: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // Ensure image fits the screen properly
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Habit"),
        backgroundColor: Color(0xFF4E48E0),
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
                          child: Card(
                            color: Colors.grey[200], // Light background for contrast
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2, // Subtle shadow for a polished look
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Red square
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12), // Spacing between square & text
                                  // "Tap to open" text
                                  Text(
                                    "Tap to open",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
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
                          color: isSentByUser ? Color(0xFF4E48E0) : Color(0XE5E1FF),
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
