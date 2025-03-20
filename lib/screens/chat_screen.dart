import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({Key? key, required this.receiverId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    fetchReceiverPhoneNumber();
  }

  Future<void> fetchReceiverPhoneNumber() async {
    final receiverDoc =
        await _firestore.collection('users').doc(widget.receiverId).get();
    if (receiverDoc.exists) {
      setState(() {
        phoneNumber = receiverDoc['phoneNumber'];
      });
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber != null) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              _makePhoneCall(phoneNumber);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_getChatId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == _auth.currentUser!.uid;

                    return ListTile(
                      title: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(message['text']),
                        ),
                      ),
                    );
                  },
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatId() {
    final currentUserId = _auth.currentUser!.uid;
    final receiverId = widget.receiverId;
    return currentUserId.compareTo(receiverId) < 0
        ? '$currentUserId-$receiverId'
        : '$receiverId-$currentUserId';
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'text': _messageController.text.trim(),
      'senderId': _auth.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _firestore
        .collection('chats')
        .doc(_getChatId())
        .collection('messages')
        .add(message);

    _messageController.clear();
  }
}
