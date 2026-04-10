import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_seller/components/chat_bubble.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/my_textfield.dart';
import 'package:unshelf_seller/core/interfaces/i_chat_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class ChatView extends StatefulWidget {
  final String receiverName;
  final String receiverUserID;
  const ChatView({
    super.key,
    required this.receiverName,
    required this.receiverUserID,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _messageController = TextEditingController();
  final IChatService _chatService = locator<IChatService>();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserID, _messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: CustomAppBar(
          title: widget.receiverName,
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          const SizedBox(height: AppTheme.spacing24),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        widget.receiverUserID,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing8),
        child: Column(
          crossAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          mainAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing4),
            (data['senderId'] == _firebaseAuth.currentUser!.uid)
                ? ChatBubble(message: data['message'], type: 'sender')
                : ChatBubble(message: data['message'], type: 'receiver'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: 'Enter message',
              obscureText: false,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send,
              size: 30,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
