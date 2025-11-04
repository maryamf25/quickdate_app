import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart'; // for access_token
import 'random_user_profile_screen.dart'; // new screen
import 'social_login_service.dart';
import 'filter_screen.dart';
import 'credits_screen.dart';

class _HotOrNotFullCard extends StatelessWidget {
  final dynamic user;
  const _HotOrNotFullCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image section
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  user['avater']?.toString() ?? '',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 300, color: Colors.grey[300]),
                ),
              ),

              // Cross and Fire buttons
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cross (Purple)
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8A2BE2), // Purple tone
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x448A2BE2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 60),
                    // Fire (Shocky Pink)
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1493), // Shocking pink
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x44FF1493),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Name + Country
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  user['username']?.toString() ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user['country_txt'] != null)
                  Text(
                    user['country_txt'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}
class _HotOrNotFullScreen extends StatelessWidget {
  final List<dynamic> users;

  const _HotOrNotFullScreen({required this.users});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.7,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '🔥 Hot or Not - All Users',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _HotOrNotFullCard(user: user);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HotOrNotMiniCard extends StatelessWidget {
  final dynamic user;
  const _HotOrNotMiniCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RandomUserProfileScreen(user: user),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              user['avater']?.toString() ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user['country_txt'] != null)
                    Text(
                      user['country_txt'].toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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

class _TrendingScreenState extends State<TrendingScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  List<dynamic> _friends = [];
  List<dynamic> _hotOrNotUsers = [];
  List<dynamic> _filteredFriends = [];
  List<dynamic> _filteredHotOrNotUsers = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _filteredSearchResults = [];
  bool _isLoading = true;
  late AnimationController _swipeAnimationController;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  static const double horizontalPadding = 10;
  static const double maxCardWidth = 420;
  static const double cardAspect = 0.78;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );


    _fetchFriends();
    _fetchHotOrNotUsers();
  }


  Future<void> _fetchFriends() async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/random_users');

    // Build request body with filter parameters
    Map<String, String> requestBody = {
      'access_token': UserDetails.accessToken,
    };

    // Add filter parameters
    if (UserDetails.filterOptionIsOnline) {
      requestBody['online'] = '1';
    }

    // Add gender filter (convert from UI format to API format)
    String genderFilter = UserDetails.filterOptionGender;
    if (genderFilter.isNotEmpty && genderFilter != '4525,4526') {
      requestBody['genders'] = genderFilter;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          List<dynamic> rawFriends = List<dynamic>.from(data['data']);
          print('Friend data: ${rawFriends.length}');

          // Debug: print email, username, password, is_pro for all users
          for (var user in rawFriends) {
            print('--- User ---');
            print('Username: ${user['username']}');
            print('Email: ${user['email']}');
            print('Password: ${user['password']}');
            print('is_pro: ${user['is_pro']}');
          }

          // Apply client-side filters for parameters not supported by backend
          List<dynamic> filteredData = _applyClientSideFilters(rawFriends);
          print('Filtered friend data: ${filteredData.length}');
          setState(() {
            _friends = filteredData;
            _filteredFriends = _friends;
          });
        } else {
          setState(() {
            _friends = [];
            _filteredFriends = [];
          });
        }
      } else {
        setState(() => _friends = []);
      }
    } catch (e) {
      setState(() => _friends = []);
      print('Error fetching friends: $e');
    }
  }


  Future<void> _fetchHotOrNotUsers() async {
    // Use the dedicated get_hot_or_not endpoint as specified in the PHP code
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/get_hot_or_not');

    // Build request body with filter parameters
    Map<String, String> requestBody = {
      'access_token': UserDetails.accessToken,
      'limit': '10',
      'offset': '0',
    };

    // Add filter parameters
    if (UserDetails.filterOptionIsOnline) {
      requestBody['online'] = '1';
    }

    // Add gender filter (convert from UI format to API format)
    String genderFilter = UserDetails.filterOptionGender;
    if (genderFilter.isNotEmpty && genderFilter != '4525,4526') {
      requestBody['genders'] = genderFilter;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          if (data['data'] != null && data['data'] is List) {
            List<dynamic> rawUsers = List<dynamic>.from(data['data']);

            // Apply client-side filters for parameters not supported by backend
            List<dynamic> filteredData = _applyClientSideFilters(rawUsers);

            setState(() {
              _hotOrNotUsers = filteredData;
              _filteredHotOrNotUsers = _hotOrNotUsers;
              _isLoading = false;
            });
          } else {
            setState(() {
              _hotOrNotUsers = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _hotOrNotUsers = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hotOrNotUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hotOrNotUsers = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _rateUserAsHot(String userId) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/hot');
    print('🔥 Rating user $userId as HOT');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'user_id': userId,
        },
      );

      print('📡 Hot rating response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          _removeUserFromHotOrNot(userId);
          print('✅ User $userId successfully rated as HOT');
        } else {
          print('❌ Hot rating failed: ${data['message']}');
        }
      }
    } catch (e) {
      print('💥 Error rating user as hot: $e');
    }
  }

  Future<void> _rateUserAsNot(String userId) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/not');
    print('❌ Rating user $userId as NOT');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'user_id': userId,
        },
      );

      print('📡 Not rating response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          _removeUserFromHotOrNot(userId);
          print('✅ User $userId successfully rated as NOT');
        } else {
          print('❌ Not rating failed: ${data['message']}');
        }
      }
    } catch (e) {
      print('💥 Error rating user as not: $e');
    }
  }

  void _removeUserFromHotOrNot(String userId) {
    final index = _hotOrNotUsers.indexWhere((user) => user['id'].toString() == userId);
    if (index != -1 && mounted) {
      // Animate removal
      _swipeAnimationController.forward().then((_) {
        setState(() {
          _hotOrNotUsers.removeAt(index);
          _filteredHotOrNotUsers.removeAt(_filteredHotOrNotUsers.indexWhere((user) => user['id'].toString() == userId));
        });
        _swipeAnimationController.reset();
      });
    }
  }

  void _searchUsers(String query) {
    print('Search query: "$query"'); // Debug: show the search query

    setState(() {

      // 🧩 Combine all users (friends + hot/not)
      List<dynamic> combinedUsers = [..._friends, ..._hotOrNotUsers];

      // 🎯 Apply filters if enabled
      combinedUsers = combinedUsers.where((user) {
        bool matches = true;

        // Filter: online only
        if (UserDetails.filterOptionIsOnline) {
          matches = matches && (user['online'] == true || user['online'] == 1);
        }

        // Filter: gender
        String genderFilter = UserDetails.filterOptionGender;
        if (genderFilter.isNotEmpty && genderFilter != '4525,4526') {
          matches = matches && genderFilter.contains(user['gender'].toString());
        }

        return matches;
      }).toList();

      // 🔎 If query is empty → show all users (filtered + unique)
      if (query.isEmpty) {
        final uniqueMap = {for (var u in combinedUsers) u['id']: u};
        _filteredSearchResults = uniqueMap.values.toList();

        print('Query empty → showing all unique users: ${_filteredSearchResults.length}');
      } else {
        // 🔍 If query has text → search by username
        final lowerQuery = query.toLowerCase();

        final filteredFriends = _friends.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          final match = username.contains(lowerQuery);
          if (match) print('Friend matched: $username');
          return match;
        }).toList();

        final filteredHotOrNot = _hotOrNotUsers.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          final match = username.contains(lowerQuery);
          if (match) print('Hot/Not matched: $username');
          return match;
        }).toList();

        // ✨ Merge and remove duplicates by user['id']
        final merged = [...filteredFriends, ...filteredHotOrNot];
        final uniqueMap = {for (var u in merged) u['id']: u};
        _filteredSearchResults = uniqueMap.values.toList();

        print('Filtered unique results count: ${_filteredSearchResults.length}');
      }

      // Update global search results
      _searchResults = _filteredSearchResults;

      print('✅ Final search results (unique): ${_searchResults.length}');
    });
  }



  bool _hasActiveFilters() {
    return UserDetails.filterOptionIsOnline ||
        UserDetails.filterOptionGender != "4525,4526" ||
        UserDetails.filterOptionAgeMin != 18 ||
        UserDetails.filterOptionAgeMax != 75 ||
        UserDetails.filterOptionDistance != "35" ||
        UserDetails.filterOptionBodyTypes.isNotEmpty ||
        UserDetails.filterOptionHeightMin != 150 ||
        UserDetails.filterOptionHeightMax != 200 ||
        UserDetails.filterOptionLanguage != "english" ||
        UserDetails.filterOptionReligion != "Any" ||
        UserDetails.filterOptionEthnicities.isNotEmpty ||
        UserDetails.filterOptionRelationship != "Any" ||
        UserDetails.filterOptionSmoking != "Any" ||
        UserDetails.filterOptionDrinking != "Any";
  }

  List<dynamic> _applyClientSideFilters(List<dynamic> users) {
    return users.where((user) {
      // Age filter
      if (UserDetails.filterOptionAgeMin != 18 || UserDetails.filterOptionAgeMax != 75) {
        if (user['age'] != null) {
          try {
            int age = int.parse(user['age'].toString());
            if (age < UserDetails.filterOptionAgeMin || age > UserDetails.filterOptionAgeMax) return false;
          } catch (_) {}
        }
      }

      // Body type filter
      if (UserDetails.filterOptionBodyTypes.isNotEmpty && user['body'] != null) {
        String bodyType = user['body'].toString().toLowerCase();
        bool match = UserDetails.filterOptionBodyTypes.any((filterBody) =>
            bodyType.contains(filterBody.toLowerCase()));
        if (!match) return false;
      }

      // Height filter
      if (UserDetails.filterOptionHeightMin != 150 || UserDetails.filterOptionHeightMax != 200) {
        if (user['height'] != null) {
          try {
            double height = double.parse(user['height'].toString());
            if (height < UserDetails.filterOptionHeightMin || height > UserDetails.filterOptionHeightMax) return false;
          } catch (_) {}
        }
      }

      // Language filter
      if (UserDetails.filterOptionLanguage.toLowerCase() != "english" &&
          UserDetails.filterOptionLanguage.toLowerCase() != "any") {
        if (user['language'] != null &&
            user['language'].toString().toLowerCase() != UserDetails.filterOptionLanguage.toLowerCase())
          return false;
      }

      // Religion filter
      if (UserDetails.filterOptionReligion != "Any" && user['religion'] != null) {
        if (user['religion'].toString().toLowerCase() != UserDetails.filterOptionReligion.toLowerCase())
          return false;
      }

      // Ethnicity filter
      if (UserDetails.filterOptionEthnicities.isNotEmpty && user['ethnicity'] != null) {
        String userEthnicity = user['ethnicity'].toString().toLowerCase();
        bool match = UserDetails.filterOptionEthnicities.any(
                (filterEthnicity) => userEthnicity.contains(filterEthnicity.toLowerCase()));
        if (!match) return false;
      }

      // Relationship filter
      if (UserDetails.filterOptionRelationship != "Any" && user['relationship'] != null) {
        if (user['relationship'].toString().toLowerCase() != UserDetails.filterOptionRelationship.toLowerCase())
          return false;
      }

      // Smoking filter
      if (UserDetails.filterOptionSmoking != "Any" && user['smoke'] != null) {
        String u = user['smoke'].toString().toLowerCase();
        String f = UserDetails.filterOptionSmoking.toLowerCase();
        if (f == "non-smoker" && u != "0" && u != "no") return false;
        if (f == "smoker" && u != "1" && u != "yes") return false;
        if (f == "occasionally" && !u.contains("occasion")) return false;
      }

      // Drinking filter
      if (UserDetails.filterOptionDrinking != "Any" && user['drink'] != null) {
        String u = user['drink'].toString().toLowerCase();
        String f = UserDetails.filterOptionDrinking.toLowerCase();
        if (f == "non-drinker" && u != "0" && u != "no") return false;
        if (f == "social drinker" && !u.contains("social")) return false;
        if (f == "regular drinker" && !u.contains("regular")) return false;
      }

      return true;
    }).toList();
  }

  void _openUserProfile(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RandomUserProfileScreen(user: user),
      ),
    );
  }
  void _openSearchOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Search",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF8D3E7),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Icon(Icons.search, color: Colors.black),
                              const SizedBox(width: 10),

                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  cursorColor: Colors.black,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    hintText: 'Search users...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.black54),
                                  ),
                                  onChanged: (query) {
                                    _searchUsers(query);
                                    setDialogState(() {}); // 🔥 refresh dialog UI
                                  },
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.tune, color: Colors.black),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FilterScreen()),
                                  );
                                  if (result == true) {
                                    _fetchFriends();
                                    _fetchHotOrNotUsers();
                                    setDialogState(() {});
                                  }
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.black),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchUsers('');
                                  setDialogState(() {});
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔎 Search Results List
                        Expanded(
                          child: _searchResults.isEmpty
                              ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                              : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user['avater'] != null &&
                                      user['avater'].toString().isNotEmpty
                                      ? NetworkImage(user['avater'])
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                ),
                                title: Text(
                                  user['username'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                subtitle: Text(
                                  user['country_txt'] ?? '',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _openUserProfile(user);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }


  @override
  void dispose() {
    _pageController.dispose();
    _swipeAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building Trending Screen - Loading: $_isLoading');
    print('👥 Friends count: ${_friends.length}');
    print('🔥 Hot or Not users count: ${_hotOrNotUsers.length}');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ removes back button
        title: _showSearchBar
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _searchUsers,
        )
            : const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        actions: [
          // 🔍 Search Button (white circular background)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.black87, size: 20),
                onPressed: () => _openSearchOverlay(context),


              ),
            ),
          ),

          // ⚙️ Filter Button (white circular background)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FilterScreen()),
                      );
                      if (result == true) {
                        _fetchFriends();
                        _fetchHotOrNotUsers();
                      }
                    },
                  ),
                ),
                // 🔴 Small red dot if filters active
                if (_hasActiveFilters())
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),

          // 🕒 Credits Button (pink circle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFFF41BD),
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.speed, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreditsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [

          // Stories Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: (_filteredFriends.isEmpty || _filteredFriends.length == 0)
                  ? Container(
                height: 100,
                child: const Center(
                  child: Text('No friends data loaded'),
                ),
              )
                  : StoriesBar(friends: _filteredFriends),
            ),
          ),

          // Hot or Not Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HOT OR NOT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: _HotOrNotFullScreen(users: _filteredHotOrNotUsers),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    ],
                  ),
                  if (_hasActiveFilters())
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filters Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Hot or Not Carousel
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.width * cardAspect,
                child: _filteredHotOrNotUsers.isEmpty
                    ? _buildEmptyHotOrNot()
                    : PageView.builder(
                  controller: _pageController,
                  itemCount: _filteredHotOrNotUsers.length,
                  padEnds: true,
                  itemBuilder: (context, index) {
                    final user = _filteredHotOrNotUsers[index];
                    return AnimatedBuilder(
                      animation: _swipeAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _swipeAnimationController.value * 100),
                          child: Opacity(
                            opacity: 1 - _swipeAnimationController.value,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: maxCardWidth),
                          child: _HotOrNotCard(
                            user: user,
                            onHot: () => _rateUserAsHot(user['id'].toString()),
                            onNot: () => _rateUserAsNot(user['id'].toString()),
                            onProfile: () => _openUserProfile(user),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Regular User Profile Cards
          if (_filteredFriends.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final user = _filteredFriends[index];
                    return UserProfileCard(
                      nameAndAge: "${user['username'] ?? 'Unknown'}, ${user['age'] ?? '--'}",
                      imageUrl: user['avater']?.toString() ?? '',
                      isOnline: user['online'] == "1" || user['online'] == 1,
                      onCardTap: () => _openUserProfile(user),
                      onLikePressed: () => _openUserProfile(user),
                    );

                      },
                  childCount: _filteredFriends.length,
                ),
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildEmptyHotOrNot() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No users available for Hot or Not!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'All users have been rated or no eligible users found',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHotOrNotUsers,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotOrNotCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onHot;
  final VoidCallback onNot;
  final VoidCallback onProfile;

  const _HotOrNotCard({
    required this.user,
    required this.onHot,
    required this.onNot,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate 70-80% height for image (use 75% here; adjust if needed)
    final double cardHeight = MediaQuery.of(context).size.width * 0.78; // Based on your cardAspect
    final double imageHeight = cardHeight * 0.75;
    final double overlap = 30; // Amount icons overlap the border

    return GestureDetector(
      onTap: onProfile,
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Row 1: Profile Image (70-80%)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                user['avater']?.toString() ?? '',
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: imageHeight,
                  color: Colors.grey[300],
                ),
              ),
            ),

            // Row 2: White area with name + country (below image)
            Positioned(
              top: imageHeight - overlap / 2, // Slight overlap for smooth transition
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                color: Colors.white, // Change to Colors.pink[50] if you want slightly pink
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name + Country (left-aligned)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user['username']?.toString() ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (user['country_txt'] != null)
                            Text(
                              user['country_txt'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Icons: Overlapping border (half on image, half on white)
            Positioned(
              right: 20,
              bottom: cardHeight - imageHeight - overlap / 2, // Half above/below border
              child: Row(
                children: [
                  // Not button (purple)
                  GestureDetector(
                    onTap: onNot,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8A2BE2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x338A2BE2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Hot button (pink)
                  GestureDetector(
                    onTap: onHot,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF41BD),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33FF41BD),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                    ),
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
// Hot or Not Action Button
class _HotOrNotButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String label;

  const _HotOrNotButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class StoriesBar extends StatelessWidget {
  final List<dynamic> friends;
  const StoriesBar({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    // Add null safety check
    if (friends.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No stories available')),
      );
    }

    final List<Map<String, String>> stories = [
      {'name': 'Add Me', 'image': ''},
      ...friends.where((f) => f != null).map((f) => {
        'name': f['username']?.toString() ?? 'Unknown',
        'image': f['avater']?.toString() ?? '',
      }),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = stories[index];
          final isAdd = index == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StoryItem(
              name: item['name'] ?? 'Unknown',
              imageUrl: item['image'] ?? '',
              isAdd: isAdd,
              onTap: !isAdd && friends.length > (index - 1) && friends[index - 1] != null
                  ? () {
                final user = friends[index - 1];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RandomUserProfileScreen(user: user),
                  ),
                );
              }
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class StoryItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isAdd;
  final VoidCallback? onTap;

  const StoryItem({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isAdd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    const Color borderColor = Color(0xFFFF41BD);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🌸 Dotted circular border
              CustomPaint(
                size: const Size(size, size),
                painter: _DottedCirclePainter(color: borderColor, strokeWidth: 2),
              ),

              // 👤 User profile picture
              CircleAvatar(
                radius: (size - 8) / 2,
                backgroundColor: Colors.white,
                backgroundImage: (imageUrl.isNotEmpty && imageUrl != 'null')
                    ? NetworkImage(imageUrl)
                    : null,
                child: (imageUrl.isEmpty || imageUrl == 'null')
                    ? Icon(Icons.person, size: 32, color: Colors.grey[500])
                    : null,
              ),

              // ➕ Add icon overlay
              if (isAdd)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: size + 6,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

}
class _DottedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DottedCirclePainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 3;
    final double radius = (size.width / 2) - (strokeWidth / 2);
    final Path path = Path()..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: radius));

    final PathMetrics metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserProfileCard extends StatelessWidget {
  final String nameAndAge;
  final String imageUrl;
  final bool isOnline;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCardTap;

  const UserProfileCard({
    super.key,
    required this.nameAndAge,
    this.imageUrl = '',
    this.isOnline = false,
    this.onLikePressed,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            // 🖼 image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
            ),

            // 🖤 overlay for gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ❤️ like button top-right
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onLikePressed,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                  const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                ),
              ),
            ),

            // 👤 name & age bottom-left
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                nameAndAge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 🟢 online indicator
            if (isOnline)
              const Positioned(
                right: 16,
                bottom: 16,
                child: _OnlineDot(),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF30DB3C), Color(0xFF1FA12A)],
        ),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
    );
  }
}
