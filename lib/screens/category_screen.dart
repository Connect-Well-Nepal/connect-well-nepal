import 'package:flutter/material.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/article_service.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ArticleService _articleService = ArticleService();
  String _searchQuery = "";
  final Set<String> _bookmarkedArticleIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_articles') ?? [];
    setState(() {
      _bookmarkedArticleIds.addAll(bookmarks);
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarked_articles', _bookmarkedArticleIds.toList());
  }

  void _toggleBookmark(String articleId) {
    setState(() {
      if (_bookmarkedArticleIds.contains(articleId)) {
        _bookmarkedArticleIds.remove(articleId);
      } else {
        _bookmarkedArticleIds.add(articleId);
      }
    });
    _saveBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    // Get articles for this category
    final categoryArticles = _articleService.getArticlesByCategory(widget.category);

    // Filter by search query
    final filteredArticles = categoryArticles.where((article) {
      final query = _searchQuery.toLowerCase();
      return article.title.toLowerCase().contains(query) ||
             article.content.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar for category
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search in ${widget.category}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.backgroundOffWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Article count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${filteredArticles.length} article${filteredArticles.length != 1 ? 's' : ''} found',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Articles list
          Expanded(
            child: filteredArticles.isEmpty
              ? const Center(
                  child: Text('No articles found in this category.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return ArticleCard(
                      article: article,
                      isBookmarked: _bookmarkedArticleIds.contains(article.id),
                      onBookmarkToggle: () => _toggleBookmark(article.id),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: article),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}