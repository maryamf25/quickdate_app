import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'random_user_profile_screen.dart';
// -------------------- User Model --------------------
class User {
  final String id;
  final String username;  // <-- added
  final String fullname;
  final String avatar;
  final int age;
  final String country;
  final String bio;

  User({
    required this.id,
    required this.username,  // <-- added
    required this.fullname,
    required this.avatar,
    required this.age,
    required this.country,
    required this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',  // <-- initialize username
      fullname: (json['fullname'] ??
          '${json['first_name'] ?? 'Unknown'} ${json['last_name'] ?? ''}')
          .trim(),
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
  String selectedGender = 'both';
  bool onlineOnly = false;
  DateTime? selectedBirthday;

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
      final body = {
        'access_token': accessToken,
        'limit': '20',
        'genders': selectedGender == 'both' ? '' : selectedGender,
        'online': onlineOnly ? '1' : '0',
        if (selectedBirthday != null)
          'birthday': DateFormat('yyyy-MM-dd').format(selectedBirthday!), // ✅ add this
      };


      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['data'] != null && jsonData['data'] is List) {
          final data = jsonData['data'] as List<dynamic>;
          final fetched = data.map((u) => User.fromJson(u)).toList();

          if (mounted) {
            setState(() {
              _users = fetched; // ✅ just show what came, even if empty
              _loading = false;
            });
          }
        } else {
          // backend didn't send expected data format
          _setDummyUsers();
        }

      } else {
        _setDummyUsers();
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
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
      username: 'aisha123', // added
      fullname: 'Aisha',
      age: 24,
      avatar: 'https://i.pravatar.cc/400?img=10',
      country: 'PK',
      bio: 'Coffee & travel',
    ),
    User(
      id: '102',
      username: 'sara456', // added
      fullname: 'Sara',
      age: 27,
      avatar: 'https://i.pravatar.cc/400?img=11',
      country: 'PK',
      bio: 'Designer',
    ),
    User(
      id: '103',
      username: 'maya789', // added
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
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String tempGender = selectedGender;
        bool tempOnline = onlineOnly;
        DateTime? tempBirthday;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🧩 Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Filters",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 24),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🧍 Gender
                        const Text(
                          "Who are you looking for?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _pillButton(
                              label: "Girls",
                              isSelected: tempGender == "female",
                              onTap: () =>
                                  setSheetState(() => tempGender = "female"),
                            ),
                            _pillButton(
                              label: "Boys",
                              isSelected: tempGender == "male",
                              onTap: () =>
                                  setSheetState(() => tempGender = "male"),
                            ),
                            _pillButton(
                              label: "Both",
                              isSelected: tempGender == "both",
                              onTap: () =>
                                  setSheetState(() => tempGender = "both"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // 🎂 Birthday (pill)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1960),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFFF0881),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setSheetState(() => tempBirthday = picked);
                              }
                            },

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 34,
                                      width: 34,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF6EBF0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Color(0xFFFF0881),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      tempBirthday == null
                                          ? "Select Birthday"
                                          : "${tempBirthday!.day}/${tempBirthday!.month}/${tempBirthday!.year}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 🌐 Online Now (pill)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // 🔘 custom circle-in-circle icon
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6EBF0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF0881),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Online Now",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Transform.scale(
                                scale: 1.3,
                                child: Switch(
                                  value: tempOnline,
                                  activeColor: const Color(0xFFFF0881),
                                  inactiveTrackColor:
                                  Colors.grey.shade300.withOpacity(0.6),
                                  inactiveThumbColor: Colors.white,
                                  materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent),
                                  onChanged: (v) =>
                                      setSheetState(() => tempOnline = v),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ✅ Apply Filter (gradient button)
                        Container(
                          width: double.infinity,
                          height: 58,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFE40997),
                                Color(0xFFF20489),
                                Color(0xFFDC0C9F),
                                Color(0xFFCA12AF),
                                Color(0xFFBA16C1),
                                Color(0xFFAA1BCD),
                                Color(0xFF9921E0),
                                Color(0xFF8926F0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedGender = tempGender;
                                onlineOnly = tempOnline;
                                selectedBirthday = tempBirthday; // ✅ added
                              });
                              Navigator.pop(context);
                              _fetchUsers();
                            },

                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ♻️ Reset Filter (no border)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(onPressed: () {
                            setState(() {
                              selectedGender = 'both';
                              onlineOnly = false;
                              selectedBirthday = null; // ✅ reset actual state variable too
                            });
                            Navigator.pop(context);
                            _fetchUsers();
                          },

                            child: const Text(
                              "Reset Filters",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 💕 Reusable pill-shaped button for gender chips

  Widget _pillButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded( // 🔹 makes each button take equal width in row
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 14), // taller height
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF0881)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFFFF0881).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  /// 💖 Reusable pill-shaped icon button (for birthday / online)
  Widget _pillIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFFEBF4)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: const Color(0xFFFF0881).withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: const Color(0xFFFF0881), size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(
      String label, String value, String selected, Function(String) onSelect) {
    final bool isActive = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF0881) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_users.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFDFBFC),
                Color(0xFFFDF8FA),
                Color(0xFFFEEEF7),
                Color(0xFFFDDDED),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_rounded,
                        color: Color(0xFFFF0881), size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'No matches found nearby',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Try adjusting your filters or broadening your search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 🔄 Reload Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _fetchUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0881),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Reload",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ♻️ Reset Filters
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedGender = 'both';
                            onlineOnly = false;
                            selectedBirthday = null;
                          });
                          _fetchUsers(); // ✅ refresh without filters
                        },
                        child: const Text(
                          "Reset Filters",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }


    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDFBFC),
                  Color(0xFFFDF8FA),
                  Color(0xFFFEEEF7),
                  Color(0xFFFDDDED),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🧩 1. Top — Filter Button Centered
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: _openFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: selectedGender != 'both' || onlineOnly
                                ? const Color(0xFFFF0881)
                                : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🧍 2. Middle — Swipe Cards
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int i = _users.length - 1; i >= 0; i--)
                            Positioned(
                              top: 8.0 + (i * 6),
                              child: _buildCard(_users[i], i == 0),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 🌈 3. Bottom — Action Buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🔄 Refresh
                        AnimatedCircleButton(
                          icon: Icons.refresh,
                          iconColor: const Color(0xFFFF0881),
                          bgColor: const Color(0xFFFFEEF8),
                          onTap: _fetchUsers,
                          size: 60,
                        ),
                        const SizedBox(width: 24),
                        // ❌ Dislike
                        AnimatedCircleButton(
                          icon: Icons.close,
                          bgColor: const Color(0xFFF6F1F8),
                          iconColor: const Color(0xFFB602F5),
                          onTap: () => _handleDislike(_users[0].id),
                          size: 60,
                        ),
                        const SizedBox(width: 24),
                        // ❤️ Like
                        AnimatedCircleButton(
                          icon: Icons.favorite,
                          iconColor: Colors.white,
                          bgColor: const Color(0xFFFF0881),
                          onTap: () => _handleLike(_users[0].id),
                          size: 60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        )
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

    if (_position.dx > threshold) {
      widget.onLike();
    } else if (_position.dx < -threshold) {
      widget.onDislike();
    } else {
      _animateBack();
    }
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
    final h = MediaQuery.of(context).size.height * 0.60;

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RandomUserProfileScreen(
                  user: {
                    'id': widget.user.id,
                    'username': widget.user.username,
                    'avatar': widget.user.avatar,
                    'fullName': widget.user.fullname,
                    'country': widget.user.country,
                  },
                ),
              ),
            );
          },

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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: widget.user.avatar.isNotEmpty
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
                      if (widget.user.country.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            widget.user.country,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              // 🌈 Like/Dislike overlays
              Positioned.fill(
                child: Stack(
                  children: [
                    // 💖 LIKE overlay — pink tint
                    if (likeOpacity > 0)
                      Opacity(
                        opacity: likeOpacity * 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0881),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    if (likeOpacity > 0)
                      Opacity(
                        opacity: likeOpacity,
                        child: const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      ),

                    // ❌ DISLIKE overlay — purple tint
                    if (dislikeOpacity > 0)
                      Opacity(
                        opacity: dislikeOpacity * 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFB602F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    if (dislikeOpacity > 0)
                      Opacity(
                        opacity: dislikeOpacity,
                        child: const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close,
                            color: Color(0xFFE3CDEA),
                            size: 100,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _stamp(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// -------------------- Animated Button --------------------
class AnimatedCircleButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final double size;

  const AnimatedCircleButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    required this.size,
  });

  @override
  State<AnimatedCircleButton> createState() => _AnimatedCircleButtonState();
}

class _AnimatedCircleButtonState extends State<AnimatedCircleButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.9);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.iconColor, size: widget.size * 0.45),
        ),
      ),
    );
  }
}
