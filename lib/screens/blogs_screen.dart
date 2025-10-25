import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      appBar: AppBar(title: const Text("Blogs")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
          ? const Center(child: Text("No blogs found."))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article?['title'] ?? "Blog Detail")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : article == null
          ? const Center(child: Text("Article not found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article!['thumbnail'] != null)
              Image.network(article!['thumbnail']),
            const SizedBox(height: 10),
            Text(
              article!['title'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article!['category_name'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(article!['content'] ?? ''),
          ],
        ),
      ),
    );
  }
}
