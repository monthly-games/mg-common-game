import 'dart:async';
import 'package:flutter/material.dart';

class MessageQueue {
  final String queueId;
  final List<Message> _messages = [];

  MessageQueue({required this.queueId});

  void enqueue(Message message) {
    _messages.add(message);
  }

  Message? dequeue() {
    if (_messages.isEmpty) return null;
    return _messages.removeAt(0);
  }

  int get length => _messages.length;
}

class Message {
  final String messageId;
  final String content;
  final Map<String, dynamic> headers;
  final DateTime timestamp;

  const Message({
    required this.messageId,
    required this.content,
    required this.headers,
    required this.timestamp,
  });
}

class MessageQueueManager {
  static final MessageQueueManager _instance = MessageQueueManager._();
  static MessageQueueManager get instance => _instance;

  MessageQueueManager._();

  final Map<String, MessageQueue> _queues = {};
  final StreamController<Message> _controller = StreamController.broadcast();

  Stream<Message> get onMessage => _controller.stream;

  MessageQueue createQueue(String queueId) {
    final queue = MessageQueue(queueId: queueId);
    _queues[queueId] = queue;
    return queue;
  }

  Future<void> publish({
    required String queueId,
    required String content,
    Map<String, dynamic>? headers,
  }) async {
    final message = Message(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      headers: headers ?? {},
      timestamp: DateTime.now(),
    );

    _queues[queueId]?.enqueue(message);
    _controller.add(message);
  }

  Future<Message?> subscribe(String queueId) async {
    return _queues[queueId]?.dequeue();
  }

  void dispose() {
    _controller.close();
  }
}
