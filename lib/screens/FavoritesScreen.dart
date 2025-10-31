import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class FavoritesGridScreen extends StatefulWidget {
  final String accessToken;

  const FavoritesGridScreen({super.key, required this.accessToken});

  @override
  State<FavoritesGridScreen> createState() => _FavoritesGridScreenState();
}

class _FavoritesGridScreenState extends State<FavoritesGridScreen> {
  List favorites = [];
  bool isLoading = false;
  int offset = 0;
  int limit = 12;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    setState(() => isLoading = true);

    final uri = Uri.parse(
      'https://backend.staralign.me/endpoint/v1/models/users/list_favorites',
    );

    final response = await http.post(uri, body: {
      'access_token': widget.accessToken,
      'offset': offset.toString(),
      'limit': limit.toString(),
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        favorites.addAll(data['data']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_load_favorites)),
      );
    }
  }

  Future<void> removeFavorite(dynamic userId) async {
    final int uid = int.tryParse(userId.toString()) ?? 0;
    if (uid == 0) return;

    final uri = Uri.parse(
      'https://backend.staralign.me/endpoint/v1/models/users/delete_favorites',
    );

    try {
      final response = await http.post(uri, body: {
        'access_token': widget.accessToken,
        'uid': uid.toString(),
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        setState(() {
          favorites.removeWhere((fav) => int.tryParse(fav['userData']['id'].toString()) == uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.removed_from_favorites)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['errors']?['error_text'] ?? 'Failed to remove favorite')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_with_message('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_favorite_users)),
      body: isLoading && favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: favorites.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          if (index == favorites.length) {
            // Load more button
            return GestureDetector(
              onTap: () {
                offset += 1;
                fetchFavorites();
              },
              child: Card(
                color: Colors.grey[200],
                child: Center(child: Text(AppLocalizations.of(context)!.load_more)),
              ),
            );
          }

          final user = favorites[index]['userData'];
          final avatar = user['avater'] ?? '';
          final fullName =
              user['full_name'] ?? '${user['first_name']} ${user['last_name']}';
          final online = user['online'] == 1;
          final country = user['country_txt'] ?? '';
          final userId = user['id'];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                    child: avatar.isNotEmpty
                        ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        country,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: online ? Colors.green : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.pink),
                        onPressed: () => removeFavorite(userId),
                        tooltip: 'Remove from Favorites',
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
