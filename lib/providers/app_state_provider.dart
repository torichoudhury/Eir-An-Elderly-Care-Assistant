import 'package:flutter/material.dart';

class AppStateProvider with ChangeNotifier {
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage(String text, bool isUser) {
    _messages.add(Message(text: text, isUser: isUser, timestamp: DateTime.now()));
    notifyListeners();
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}