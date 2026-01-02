import 'package:flutter/material.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_articles') ?? [];
    setState(() {
      _isBookmarked = bookmarks.contains(widget.article.id);
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_articles') ?? [];
    
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (_isBookmarked) {
      bookmarks.add(widget.article.id);
    } else {
      bookmarks.remove(widget.article.id);
    }

    await prefs.setStringList('bookmarked_articles', bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            color: _isBookmarked ? Colors.blue : null,
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
              ),
              child: widget.article.imageUrl.startsWith('assets/')
                ? Image.asset(
                    widget.article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  )
                : Image.network(
                    widget.article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Title
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Article Metadata
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.article.author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.article.readTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Publish Date
                  Text(
                    'Published ${widget.article.publishDate.toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Article Content
                  Text(
                    widget.article.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tags
                  if (widget.article.tags.isNotEmpty) ...[
                    const Text(
                      'Tags:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavyBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.article.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Related Articles Section (placeholder)
                  const Text(
                    'Related Articles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavyBlue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Placeholder for related articles
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Related articles will be shown here'),
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