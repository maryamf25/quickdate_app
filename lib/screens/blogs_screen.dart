import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlogsScreen extends StatefulWidget {
  final String accessToken;

  const BlogsScreen({super.key, required this.accessToken});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  List<dynamic> articles = [];
  bool loading = true;
  int limit = 20;
  int offset = 0;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    final uri = Uri.parse('https://backend.staralign.me/endpoint/v1/models/blogs/Articles');

    final response = await http.post(
      uri,
      body: {
        'access_token': widget.accessToken,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        setState(() {
          articles.addAll(data['data']);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
      debugPrint('Error fetching blogs: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_blogs)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.no_blogs_found))
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: article['thumbnail'] != null
                  ? Image.network(
                article['thumbnail'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.article, size: 40),
              title: Text(article['title'] ?? 'No Title'),
              subtitle: Text(article['category_name'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlogDetailScreen(
                      articleId: article['id'],
                      accessToken: widget.accessToken,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BlogDetailScreen extends StatefulWidget {
  final String accessToken;
  final int articleId;

  const BlogDetailScreen({
    super.key,
    required this.accessToken,
    required this.articleId,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  Map<String, dynamic>? article;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchArticle();
  }

  Future<void> fetchArticle() async {
    final uri = Uri.parse('https://backend.staralign.me/endpoint/v1/models/blogs/Article');

    final response = await http.post(uri, body: {
      'access_token': widget.accessToken,
      'id': widget.articleId.toString(),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        setState(() {
          article = data['data'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
      debugPrint('Error fetching article: ${response.statusCode}');
    }
  }

  // Try to derive a usable URL for sharing/copying. Prefer explicit fields if present.
  String? _deriveArticleUrl() {
    if (article == null) return null;
    final a = article!;
    // If backend already returns a full public URL, prefer that
    for (final key in ['url', 'link', 'post_url', 'postLink', 'article_url', 'permalink']) {
      if (a.containsKey(key) && a[key] != null && a[key].toString().isNotEmpty) {
        final value = a[key].toString();
        // If the returned URL already looks like the target domain, just return it
        if (value.contains('quickdatescript.com')) return value;
      }
    }

    // Build a URL in the form: https://quickdatescript.com/article/{id}_{slug}
    final id = a['id']?.toString();
    if (id == null || id.isEmpty) return null;

    String? slug;
    if (a.containsKey('slug') && a['slug'] != null && a['slug'].toString().isNotEmpty) {
      slug = a['slug'].toString();
    } else if (a.containsKey('title') && a['title'] != null && a['title'].toString().isNotEmpty) {
      slug = _slugify(a['title'].toString());
    } else if (a.containsKey('post_title') && a['post_title'] != null && a['post_title'].toString().isNotEmpty) {
      slug = _slugify(a['post_title'].toString());
    }

    if (slug == null || slug.isEmpty) {
      return 'https://quickdatescript.com/article/$id';
    }
    return 'https://quickdatescript.com/article/${id}_$slug';
  }

  // Simple slug generator: lowercases, replaces non-alphanumerics with '-', collapses dashes.
  String _slugify(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r"[^a-z0-9]+"), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+\$'), ''); // trim leading/trailing dashes
    return s;
  }

  Future<void> _onShare() async {
    final url = _deriveArticleUrl();
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No link available to share')),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(text: url));
  }

  Future<void> _onCopy() async {
    final url = _deriveArticleUrl();
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No link available to copy')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with share and copy actions aligned to the right
      appBar: AppBar(
        title: Text(article?['title'] ?? AppLocalizations.of(context)!.title_blogs),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: _onShare,
          ),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.copy),
            onPressed: _onCopy,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : article == null
          ? Center(child: Text(AppLocalizations.of(context)!.article_not_found))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title at top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                article!['title'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Full width image (if available)
            if (article!['thumbnail'] != null && article!['thumbnail'].toString().isNotEmpty)
              CachedNetworkImage(
                imageUrl: article!['thumbnail'],
                placeholder: (context, url) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 180,
                color: Colors.grey.shade100,
                width: double.infinity,
                child: const Center(child: Icon(Icons.article, size: 64, color: Colors.grey)),
              ),

            const SizedBox(height: 16),

            // Category (small) and content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article!['category_name'] != null && article!['category_name'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        article!['category_name'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  Text(
                    article!['content'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
