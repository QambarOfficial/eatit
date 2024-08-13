import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String selectedMenu;

  const ChatScreen({super.key, required this.selectedMenu});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final List<Message> messages = [
    Message(
        text: "Hello everyone! How's it going?",
        sender: "Admin",
        time: DateTime.now().subtract(const Duration(minutes: 10)),
        profileImage: 'assets/images/admin.png',
        reactions: []),
    Message(
        text: "Hi Admin, everything's great!",
        sender: "User1",
        time: DateTime.now().subtract(const Duration(minutes: 8)),
        profileImage: 'assets/images/user1.png',
        reactions: []),
    Message(
        text: "Hey! I have a question.",
        sender: "User2",
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        profileImage: 'assets/images/user2.png',
        reactions: []),
  ];
  bool _isTyping = false;

  void sendMessage() {
    if (messageTextController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(Message(
            text: messageTextController.text,
            sender: 'User3',
            time: DateTime.now(),
            profileImage: 'https://via.placeholder.com/50?text=User3',
            reactions: []));
        messageTextController.clear();
        _isTyping = false;
      });
    }
  }

  void addReaction(int index, String reaction) {
    setState(() {
      messages[index].reactions.add(reaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedMenu),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return MessageBubble(
                    sender: message.sender,
                    text: message.text,
                    time: message.time,
                    profileImage: message.profileImage,
                    isMe: message.sender == 'User3',
                    reactions: message.reactions,
                    onReact: (reaction) => addReaction(messages.length - 1 - index, reaction),
                  );
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'User3 is typing...',
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      decoration: const InputDecoration(
                        filled: true,
                        hintText: 'Type your message here...',
                      ),
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FloatingActionButton(
                    onPressed: sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String sender;
  final String text;
  final DateTime time;
  final String profileImage;
  final List<String> reactions;

  Message({
    required this.sender,
    required this.text,
    required this.time,
    required this.profileImage,
    required this.reactions,
  });
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final DateTime time;
  final String profileImage;
  final bool isMe;
  final List<String> reactions;
  final Function(String) onReact;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.time,
    required this.profileImage,
    required this.isMe,
    required this.reactions,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('h:mm a').format(time);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImage),
                  radius: 20,
                ),
                const SizedBox(width: 8.0),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: <Widget>[
                    Material(
                      borderRadius: isMe
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              bottomLeft: Radius.circular(30.0),
                              bottomRight: Radius.circular(30.0),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(30.0),
                              bottomLeft: Radius.circular(30.0),
                              bottomRight: Radius.circular(30.0),
                            ),
                      elevation: 5.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              text,
                              style: const TextStyle(fontSize: 15.0),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              timeString,
                              style: const TextStyle(fontSize: 10.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImage),
                  radius: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 5.0),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              ...reactions.map((reaction) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      reaction,
                      style: const TextStyle(fontSize: 18.0),
                    ),
                  )),
              IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReactionDialog(onReact: onReact),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReactionDialog extends StatelessWidget {
  final Function(String) onReact;

  const ReactionDialog({super.key, required this.onReact});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('React with an emoji'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...['😊', '👍', '❤️', '😂'].map((emoji) => IconButton(
                icon: Text(emoji, style: const TextStyle(fontSize: 30)),
                onPressed: () {
                  onReact(emoji);
                  Navigator.of(context).pop();
                },
              )),
        ],
      ),
    );
  }
}
