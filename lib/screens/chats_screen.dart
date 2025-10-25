import 'package:flutter/material.dart';

// --- Chat Model (remains the same) ---
class Chat {
  final String name;
  final String lastMessage;
  final String imageUrl;
  final bool hasUnread;
  final String time;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.imageUrl,
    this.hasUnread = false,
    required this.time,
  });
}

// --- ChatsScreen (updated) ---
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _loading = false;
  List<Chat> _chats = [];

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network call

    setState(() {
      _chats = [
        Chat(
          name: 'Alice',
          lastMessage: 'Hey, how are you?',
          imageUrl: 'https://picsum.photos/id/1005/200/200',
          hasUnread: true,
          time: '2m ago',
        ),
        Chat(
          name: 'Bob',
          lastMessage: 'Did you get my email?',
          imageUrl: 'https://picsum.photos/id/1011/200/200',
          hasUnread: false,
          time: '1h ago',
        ),
        Chat(
          name: 'Charlie',
          lastMessage: 'See you tomorrow!',
          imageUrl: 'https://picsum.photos/id/1012/200/200',
          hasUnread: true,
          time: '3h ago',
        ),
        Chat(
          name: 'Diana',
          lastMessage: 'Let\'s plan something soon.',
          imageUrl: 'https://picsum.photos/id/1015/200/200',
          hasUnread: false,
          time: 'Yesterday',
        ),
        Chat(
          name: 'Eve',
          lastMessage: 'Thanks for the help!',
          imageUrl: 'https://picsum.photos/id/1018/200/200',
          hasUnread: false,
          time: 'Yesterday',
        ),
      ];
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement new message or camera action
            },
            icon: const Icon(Icons.edit_note_outlined), // Or Icons.camera_alt
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return InkWell( // <--- Added InkWell here
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chat: chat), // <--- Pass the specific chat object
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(chat.imageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.name,
                          style: TextStyle(
                            fontWeight: chat.hasUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMessage,
                          style: TextStyle(
                            color: chat.hasUnread ? Colors.black : Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    chat.time,
                    style: TextStyle(
                      color: chat.hasUnread ? Colors.black : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (chat.hasUnread)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- ChatScreen (new widget for individual chat) ---
class ChatScreen extends StatelessWidget {
  final Chat chat; // Receive the chat object

  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16, // Smaller for AppBar
              backgroundImage: NetworkImage(chat.imageUrl),
            ),
            const SizedBox(width: 8),
            Text(chat.name), // Display the chat partner's name
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to your chat with ${chat.name}!', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Last message: "${chat.lastMessage}"'),
            // Here you would build your actual chat message list and input field
          ],
        ),
      ),
    );
  }
}