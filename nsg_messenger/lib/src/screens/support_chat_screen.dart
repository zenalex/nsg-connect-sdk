import 'package:flutter/material.dart';

/// Заглушка support-режима ChatScreen. Реальная имплементация —
/// TASK39 (help desk integration) поверх TASK15 (ChatScreen).
class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key, required this.contextId});

  final String contextId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Support: $contextId (stub)')),
    body: const Center(child: Text('SupportChatScreen — TASK39')),
  );
}
