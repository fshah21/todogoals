import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
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
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
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
    _scrollController.dispose();
    socket.disconnect();
    super.dispose();
  }

  String formatTimestamp(String timestamp) {
    try {
      DateTime utcTime = DateTime.parse(timestamp).toUtc();
      DateTime istTime = utcTime.add(Duration(hours: 5, minutes: 30)); // Convert to IST
      return DateFormat('hh:mm a').format(istTime); // Format as "04:00 PM"
    } catch (e) {
      return ''; // Handle invalid timestamps
    }
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

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        print("ScrollController has no clients yet.");
      }
    });
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    print("IN DID UPDATE WIDGET");
    super.didUpdateWidget(oldWidget);
    scrollToBottom(); // Scroll to the bottom when new messages are added
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Track Habit"),
      backgroundColor: Color(0xFF5271FF),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final senderId = message['sender_id'] ?? '';
              final isSentByUser = senderId == widget.userId;
              final timestamp = message['timestamp'] ?? ''; // Get timestamp
              final formattedTime = formatTimestamp(timestamp); // Convert to IST

              return Align(
                alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (message['message_type'] == 'image')
                        GestureDetector(
                          onTap: () => _showFullImage(message['image_url'] ?? ''),
                          child: Card(
                            color: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                        )
                      else
                        Container(
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
                      const SizedBox(height: 4), // Space for timestamp
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
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