import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';

// -------------------- User Model --------------------
class User {
  final String id;
  final String fullname;
  final String avatar;
  final int age;
  final String country;
  final String bio;

  User({
    required this.id,
    required this.fullname,
    required this.avatar,
    required this.age,
    required this.country,
    required this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullname:
          json['fullname'] ??
          '${json['first_name'] ?? 'Unknown'} ${json['last_name'] ?? ''}'
              .trim(),
      // Fix: Use 'avater' field from API
      avatar: (json['avater'] ?? json['avatar_full'] ?? '').toString().trim(),
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      country: json['country_txt'] ?? '',
      bio: json['about'] ?? '',
    );
  }
}

// -------------------- Swipe Card Screen --------------------
class CardMatchScreen extends StatefulWidget {
  const CardMatchScreen({super.key});

  @override
  State<CardMatchScreen> createState() => _CardMatchScreenState();
}

class _CardMatchScreenState extends State<CardMatchScreen> {
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);

    try {
      final accessToken = UserDetails.accessToken;
      if (accessToken.isEmpty) {
        print('⚠️ Access token is empty!');
        _setDummyUsers();
        return;
      }

      final url = Uri.parse('${SocialLoginService.baseUrl}/users/random_users');

      // Manually encode for x-www-form-urlencoded (like curl)
      final body = {'access_token': accessToken, 'limit': '20'};

      final encodedBody = body.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: encodedBody,
      );

      print('Access token: $accessToken');
      print('Request body: $encodedBody');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['data'] != null && jsonData['data'] is List) {
          final data = jsonData['data'] as List<dynamic>;

          final fetched =
              data.map((u) {
                final avatarUrl =
                    ((u['avater'] ?? u['avatar_full'] ?? '') as String).trim();
                final fullname =
                    (u['fullname'] ??
                            '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}')
                        .trim();
                final age = int.tryParse(u['age']?.toString() ?? '0') ?? 0;
                final country = u['country_txt'] ?? '';
                final bio = u['about'] ?? '';
                final id = u['id']?.toString() ?? '';

                return User(
                  id: id,
                  fullname: fullname.isEmpty ? 'Unknown' : fullname,
                  avatar: avatarUrl,
                  age: age,
                  country: country,
                  bio: bio,
                );
              }).toList();

          print('Fetched users: ${fetched.length}');

          if (mounted) {
            setState(() {
              _users = fetched.isNotEmpty ? fetched : _dummyUsers();
              _loading = false;
            });
          }
        } else {
          print('⚠️ Data is empty or missing!');
          _setDummyUsers();
        }
      } else {
        print('⚠️ Server returned status ${response.statusCode}');
        _setDummyUsers();
      }
    } catch (e, st) {
      print('Error fetching users: $e\n$st');
      _setDummyUsers();
    }
  }

  void _setDummyUsers() {
    if (mounted) {
      setState(() {
        _users = _dummyUsers();
        _loading = false;
      });
    }
  }

  List<User> _dummyUsers() => [
    User(
      id: '101',
      fullname: 'Aisha',
      age: 24,
      avatar: 'https://i.pravatar.cc/400?img=10',
      country: 'PK',
      bio: 'Coffee & travel',
    ),
    User(
      id: '102',
      fullname: 'Sara',
      age: 27,
      avatar: 'https://i.pravatar.cc/400?img=11',
      country: 'PK',
      bio: 'Designer',
    ),
    User(
      id: '103',
      fullname: 'Maya',
      age: 22,
      avatar: 'https://i.pravatar.cc/400?img=12',
      country: 'PK',
      bio: 'Photographer',
    ),
  ];

  void _handleLike(String userId) async {
    await SocialLoginService.addLikesDislikes(
      accessToken: UserDetails.accessToken,
      targetUserId: userId,
      isLike: true,
    );
    _removeTopCard();
  }

  void _handleDislike(String userId) async {
    // await SocialLoginService.addLikesDislikes(
    //   accessToken: UserDetails.accessToken,
    //   targetUserId: userId,
    //   isLike: false,
    // );
    _removeTopCard();
  }

  void _removeTopCard() {
    if (_users.isEmpty) return;
    setState(() => _users.removeAt(0));
  }

  Widget _buildCard(User user, bool isTop) {
    return DraggableCard(
      key: ValueKey(user.id),
      user: user,
      isTop: isTop,
      onLike: () => _handleLike(user.id),
      onDislike: () => _handleDislike(user.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No more people nearby', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchUsers, child: const Text('Reload')),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = _users.length - 1; i >= 0; i--)
          Positioned(top: 8.0 + (i * 6), child: _buildCard(_users[i], i == 0)),
        Positioned(
          bottom: 28,
          left: 28,
          right: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleButton(
                icon: Icons.clear,
                color: Colors.redAccent,
                onTap: () => _handleDislike(_users[0].id),
              ),
              CircleButton(
                icon: Icons.favorite,
                color: Colors.pink,
                onTap: () => _handleLike(_users[0].id),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------- Draggable Card --------------------
class DraggableCard extends StatefulWidget {
  final User user;
  final bool isTop;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const DraggableCard({
    required Key key,
    required this.user,
    required this.isTop,
    required this.onLike,
    required this.onDislike,
  }) : super(key: key);

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _angle = 0.0;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isTop) return;
    setState(() {
      _position += d.delta;
      _angle = _position.dx / 300;
    });
  }

  void _onPanEnd(DragEndDetails e) {
    if (!widget.isTop) return;
    const threshold = 140;

    if (_position.dx > threshold)
      widget.onLike();
    else if (_position.dx < -threshold)
      widget.onDislike();
    else
      _animateBack();
  }

  void _animateBack() {
    final tween = Tween<Offset>(begin: _position, end: Offset.zero);
    final angleTween = Tween<double>(begin: _angle, end: 0);
    _anim.reset();
    _anim.addListener(() {
      setState(() {
        _position = tween.evaluate(_anim);
        _angle = angleTween.evaluate(_anim);
      });
    });
    _anim.forward().whenComplete(() => _anim.removeListener(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.86;
    final h = MediaQuery.of(context).size.height * 0.72;

    final likeOpacity =
        (_position.dx > 0 ? (_position.dx / 150).clamp(0.0, 1.0) : 0.0)
            .toDouble();
    final dislikeOpacity =
        (_position.dx < 0 ? (-_position.dx / 150).clamp(0.0, 1.0) : 0.0)
            .toDouble();

    return Transform.translate(
      offset: _position,
      child: Transform.rotate(
        angle: _angle,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child:
                              widget.user.avatar.isNotEmpty
                                  ? Image.network(
                                    widget.user.avatar,
                                    width: w,
                                    height: h * 0.72,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(color: Colors.grey.shade300),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '${widget.user.fullname}, ${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.user.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            widget.user.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              // LIKE overlay
              Positioned(
                top: 40,
                left: 40,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // DISLIKE overlay
              Positioned(
                top: 40,
                right: 40,
                child: Opacity(
                  opacity: dislikeOpacity,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- CircleButton --------------------
class CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
