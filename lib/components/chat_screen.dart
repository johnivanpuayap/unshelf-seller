import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_seller/core/interfaces/i_chat_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/views/chats_view.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final IChatService _chatService = locator<IChatService>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: AppColors.lightColor,
            height: 4.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getBuyers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData) {
            return ListView.separated(
              separatorBuilder: (BuildContext context, int index) {
                return Divider(
                  color: Theme.of(context).dividerTheme.color,
                  height: 1,
                  thickness: 1,
                );
              },
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data = snapshot.data!.docs[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing4),
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall + 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatView(
                              receiverName: data['name'],
                              receiverUserID: data.id,
                            ),
                          ),
                        );
                      },
                      leading: ClipOval(
                        child: Image.network(
                          data['profileImageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        data['name'],
                        style: Theme.of(context).textTheme.titleSmall,
                      )),
                );
              },
            );
          } else {
            return const Center(child: Text('Ongoing'));
          }
        },
      ),
    );
  }
}
