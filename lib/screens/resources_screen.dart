import 'package:flutter/material.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/article_service.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';
import 'category_screen.dart';

/// ResourcesScreen - Health education and self-care resources
/// 
/// Features:
/// - Health articles
/// - Video tutorials
/// - Self-care tips
/// - Mental health resources
/// - COVID-19 information
/// 
/// TODO (Team Member 3): Populate with actual health content
/// Consider integrating a CMS or using Firebase for content management
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  // Controllers and State
  final TextEditingController _searchController = TextEditingController();
  final ArticleService _articleService = ArticleService();
  String _searchQuery = "";

  //Set for handling favorite logic
  final Set<String> _bookmarkedArticleIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
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
    // Filtering Logic
    final filteredArticles = _articleService.allArticles.where((article){
      final query =  _searchQuery.toLowerCase();
      return article.title.toLowerCase().contains(query) ||
              article.category.toLowerCase().contains(query);
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Resources'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search health topics...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.backgroundOffWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories Section modified to only show if not searching
          if (_searchQuery.isEmpty) ...[
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavyBlue,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Cards
            _buildCategoryCard(
              icon: Icons.favorite,
              title: 'Heart Health',
              color: AppColors.secondaryCrimsonRed,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'Heart Health'),
                ),
              ),
            ),
            
            _buildCategoryCard(
              icon: Icons.psychology,
              title: 'Mental Wellness',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'Mental Wellness'),
                ),
              ),
            ),
            
            _buildCategoryCard(
              icon: Icons.restaurant,
              title: 'Nutrition',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'Nutrition'),
                ),
              ),
            ),
            
            _buildCategoryCard(
              icon: Icons.fitness_center,
              title: 'Fitness & Exercise',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'Fitness & Exercise'),
                ),
              ),
            ),
            
            _buildCategoryCard(
              icon: Icons.vaccines,
              title: 'Vaccinations',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'Vaccinations'),
                ),
              ),
            ),
            
            _buildCategoryCard(
              icon: Icons.masks,
              title: 'COVID-19 Info',
              color: AppColors.primaryNavyBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: 'COVID-19 Info'),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Featured or filtered Article Section
          Text(
            _searchQuery.isEmpty ? 'Featured Articles' : 'Search Results',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavyBlue,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...filteredArticles.map((article) => ArticleCard(
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
          )).toList(),

          // Add this "Empty State" check for a professional touch
          if (filteredArticles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text("No health articles found.")),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

