import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart'; // for access_token
import 'random_user_profile_screen.dart'; // new screen
import 'social_login_service.dart';
import 'filter_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  List<dynamic> _friends = [];
  List<dynamic> _hotOrNotUsers = [];
  List<dynamic> _filteredFriends = [];
  List<dynamic> _filteredHotOrNotUsers = [];
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

    // Add debug info
    print('🚀 TrendingScreen initState');
    print('🔑 Access token available: ${UserDetails.accessToken.isNotEmpty}');
    print('👤 User ID: ${UserDetails.userId}');
    print('🎯 Current filter settings:');
    print('   • Gender: ${UserDetails.filterOptionGender}');
    print('   • Age: ${UserDetails.filterOptionAgeMin}-${UserDetails.filterOptionAgeMax}');
    print('   • Distance: ${UserDetails.filterOptionDistance} km');
    print('   • Online only: ${UserDetails.filterOptionIsOnline}');
    print('   • Filters active: ${_hasActiveFilters()}');

    _testConnectivity();
    _fetchFriends();
    _fetchHotOrNotUsers();
  }

  Future<void> _testConnectivity() async {
    print('🧪 Testing API connectivity...');
    try {
      final response = await http.get(
        Uri.parse('${SocialLoginService.baseUrl}/test'),
      );
      print('🧪 Test response: ${response.statusCode}');
    } catch (e) {
      print('🧪 Test connectivity failed: $e');
    }
  }

  Future<void> _fetchFriends() async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/random_users');
    print('🔍 Fetching friends from: $url');
    print('🔑 Access token: ${UserDetails.accessToken}');

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

    print('🎯 Request body with filters: $requestBody');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      // ...existing code...
      print('📡 Friends API Response Status: ${response.statusCode}');
      print('📄 Friends API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Friends API Data: $data');

        if (data['code'] == 200 && data['data'] != null) {
          List<dynamic> rawFriends = List<dynamic>.from(data['data']);

          // Apply client-side filters for parameters not supported by backend
          List<dynamic> filteredData = _applyClientSideFilters(rawFriends);

          setState(() {
            _friends = filteredData;
            _filteredFriends = _friends;
          });
          print('👥 Friends loaded: ${rawFriends.length} total, ${_friends.length} after client-side filtering');
        } else {
          print('❌ Friends API returned no data or error code');
          setState(() {
            _friends = [];
            _filteredFriends = [];
          });
        }
      } else {
        print('❌ Friends API failed with status: ${response.statusCode}');
        setState(() => _friends = []);
      }
    } catch (e) {
      print('💥 Error fetching friends: $e');
      setState(() => _friends = []);
    }
  }

  Future<void> _fetchHotOrNotUsers() async {
    // Use the dedicated get_hot_or_not endpoint as specified in the PHP code
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/get_hot_or_not');
    print('🔍 Fetching Hot or Not users from: $url');

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

    print('🎯 Hot or Not request body with filters: $requestBody');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      // ...existing code...
      print('📡 Hot or Not API Response Status: ${response.statusCode}');
      print('📄 Hot or Not API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Hot or Not API Data: $data');

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
            print('🔥 Hot or Not users loaded: ${rawUsers.length} total, ${_hotOrNotUsers.length} after client-side filtering');

            if (_hotOrNotUsers.isEmpty) {
              print('⚠️  No Hot or Not users found. This could mean:');
              print('   • All users have already been rated');
              print('   • No users meet the criteria (active, verified, privacy settings)');
              print('   • No other users exist in the database');
              print('   • All users are blocked or liked already');
              print('   • Current filters are too restrictive');
            }
          } else {
            print('❌ Hot or Not API data field is null or not a list');
            setState(() {
              _hotOrNotUsers = [];
              _isLoading = false;
            });
          }
        } else {
          print('❌ Hot or Not API returned error code: ${data['code']}');
          if (data['errors'] != null) {
            print('❌ Error details: ${data['errors']}');
          }
          setState(() {
            _hotOrNotUsers = [];
            _isLoading = false;
          });
        }
      } else {
        print('❌ Hot or Not API failed with status: ${response.statusCode}');
        setState(() {
          _hotOrNotUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Error fetching Hot or Not users: $e');
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
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _friends;
        _filteredHotOrNotUsers = _hotOrNotUsers;
      } else {
        _filteredFriends = _friends.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          return username.contains(query.toLowerCase());
        }).toList();

        _filteredHotOrNotUsers = _hotOrNotUsers.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          return username.contains(query.toLowerCase());
        }).toList();
      }
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
      // Age filtering (backup for server-side filtering)
      if (user['age'] != null) {
        try {
          int age = int.parse(user['age'].toString());
          if (age < UserDetails.filterOptionAgeMin || age > UserDetails.filterOptionAgeMax) {
            return false;
          }
        } catch (e) {
          // If age parsing fails, include the user
        }
      }

      // Body type filtering
      if (UserDetails.filterOptionBodyTypes.isNotEmpty && user['body'] != null) {
        String bodyType = user['body'].toString().toLowerCase();
        bool bodyMatches = UserDetails.filterOptionBodyTypes.any((filterBody) =>
          bodyType.contains(filterBody.toLowerCase()));
        if (!bodyMatches) return false;
      }

      // Height filtering
      if (user['height'] != null) {
        try {
          double height = double.parse(user['height'].toString());
          if (height < UserDetails.filterOptionHeightMin || height > UserDetails.filterOptionHeightMax) {
            return false;
          }
        } catch (e) {
          // If height parsing fails, include the user
        }
      }

      // Language filtering
      if (UserDetails.filterOptionLanguage != "english" && UserDetails.filterOptionLanguage != "any" && user['language'] != null) {
        String userLanguage = user['language'].toString().toLowerCase();
        String filterLanguage = UserDetails.filterOptionLanguage.toLowerCase();
        if (userLanguage != filterLanguage) return false;
      }

      // Religion filtering
      if (UserDetails.filterOptionReligion != "Any" && user['religion'] != null) {
        String userReligion = user['religion'].toString().toLowerCase();
        String filterReligion = UserDetails.filterOptionReligion.toLowerCase();
        if (userReligion != filterReligion) return false;
      }

      // Ethnicity filtering
      if (UserDetails.filterOptionEthnicities.isNotEmpty && user['ethnicity'] != null) {
        String userEthnicity = user['ethnicity'].toString().toLowerCase();
        bool ethnicityMatches = UserDetails.filterOptionEthnicities.any((filterEthnicity) =>
          userEthnicity.contains(filterEthnicity.toLowerCase()));
        if (!ethnicityMatches) return false;
      }

      // Relationship filtering
      if (UserDetails.filterOptionRelationship != "Any" && user['relationship'] != null) {
        String userRelationship = user['relationship'].toString().toLowerCase();
        String filterRelationship = UserDetails.filterOptionRelationship.toLowerCase();
        if (userRelationship != filterRelationship) return false;
      }

      // Smoking filtering
      if (UserDetails.filterOptionSmoking != "Any" && user['smoke'] != null) {
        String userSmoking = user['smoke'].toString().toLowerCase();
        String filterSmoking = UserDetails.filterOptionSmoking.toLowerCase();

        // Map filter values to potential API values
        if (filterSmoking == "non-smoker" && userSmoking != "0" && userSmoking != "no") return false;
        if (filterSmoking == "smoker" && userSmoking != "1" && userSmoking != "yes") return false;
        if (filterSmoking == "occasionally" && !userSmoking.contains("occasion")) return false;
      }

      // Drinking filtering
      if (UserDetails.filterOptionDrinking != "Any" && user['drink'] != null) {
        String userDrinking = user['drink'].toString().toLowerCase();
        String filterDrinking = UserDetails.filterOptionDrinking.toLowerCase();

        // Map filter values to potential API values
        if (filterDrinking == "non-drinker" && userDrinking != "0" && userDrinking != "no") return false;
        if (filterDrinking == "social drinker" && !userDrinking.contains("social")) return false;
        if (filterDrinking == "regular drinker" && !userDrinking.contains("regular")) return false;
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
          : const Text('Explore'),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchUsers(''); // Reset search results
                }
              });
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                // Show indicator if filters are active
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FilterScreen(),
                ),
              );

              // If filters were applied, refresh the data
              if (result == true) {
                print('🔄 Filters applied, refreshing data...');
                _fetchFriends();
                _fetchHotOrNotUsers();
              }
            },
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
              child: _filteredFriends.isEmpty
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
                        onTap: _fetchHotOrNotUsers,
                        child: Text(
                          'Refresh',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
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
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
              sliver: SliverToBoxAdapter(
                child: UserProfileCard(
                  nameAndAge: _filteredFriends[0]['username']?.toString() ?? 'Unknown',
                  lastSeen: 'Recently active',
                  imageUrl: _filteredFriends[0]['avater']?.toString() ?? '',
                  isOnline: _filteredFriends[0]['online'] == "1" || _filteredFriends[0]['online'] == 1,
                ),
              ),
            ),

          // More user profiles
          if (_filteredFriends.length > 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
              sliver: SliverToBoxAdapter(
                child: UserProfileCard(
                  nameAndAge: _filteredFriends[1]['username']?.toString() ?? 'Unknown',
                  lastSeen: 'Active 2h ago',
                  imageUrl: _filteredFriends[1]['avater']?.toString() ?? '',
                  isOnline: _filteredFriends[1]['online'] == "1" || _filteredFriends[1]['online'] == 1,
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

// Updated Hot or Not Card with proper functionality
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
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Section
          Expanded(
            child: GestureDetector(
              onTap: onProfile,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // User Image
                  (user['avater'] != null && user['avater'].toString().isNotEmpty)
                      ? Image.network(
                    user['avater']!.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildImagePlaceholder(),
                  )
                      : _buildImagePlaceholder(),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),

                  // User Info
                  Positioned(
                    left: 16,
                    bottom: 80,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['username']?.toString() ?? 'Unknown User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user['country'] != null || user['country_txt'] != null)
                          Text(
                            user['country_txt']?.toString() ?? user['country']?.toString() ?? 'Unknown location',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        // Show age if available
                        if (user['age'] != null || user['birthday'] != null)
                          Row(
                            children: [
                              const Icon(Icons.cake, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                user['age']?.toString() ?? 'Age unknown',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Hot/Not Buttons
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HotOrNotButton(
                          icon: Icons.close,
                          color: Colors.red,
                          onPressed: onNot,
                          label: 'Not',
                        ),
                        _HotOrNotButton(
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                          onPressed: onHot,
                          label: 'Hot',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Additional Info Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user['country_txt']?.toString() ?? user['country']?.toString() ?? 'Unknown location',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                // Online status indicator
                if (user['online'] == "1" || user['online'] == 1)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
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
    final List<Map<String, String>> stories = [
      {'name': 'Your Story', 'image': ''},
      ...friends.map((f) => {
        'name': f['username']?.toString() ?? '',
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
              name: item['name'] ?? '',
              imageUrl: item['image'] ?? '',
              isAdd: isAdd,
              onTap: !isAdd
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isAdd
                      ? null
                      : const LinearGradient(
                    colors: [Colors.pink, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: (size - 6) / 2,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person, size: 32, color: Colors.grey[600])
                      : null,
                ),
              ),
              if (isAdd)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
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

class UserProfileCard extends StatelessWidget {
  final String nameAndAge;
  final String lastSeen;
  final String imageUrl;
  final bool isOnline;
  final bool showLikeAnimation;
  final VoidCallback? onLikePressed;

  const UserProfileCard({
    super.key,
    required this.nameAndAge,
    this.lastSeen = '',
    this.imageUrl = '',
    this.isOnline = false,
    this.showLikeAnimation = false,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey[300]),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.25)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            right: 80,
            child: Text(
              nameAndAge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(lastSeen, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          if (isOnline)
            const Positioned(right: 18, bottom: 18, child: _OnlineDot()),
          Positioned(
            right: 12,
            top: 12,
            child: GestureDetector(
              onTap: onLikePressed,
              child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
            ),
          ),
          if (showLikeAnimation)
            Positioned(
              right: 8,
              top: 6,
              width: 66,
              height: 66,
              child: IgnorePointer(
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ),
        ],
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
