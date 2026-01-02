import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: article.imageUrl.startsWith('assets/')
            ? Image.asset(
                article.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              )
            : Image.network(
                article.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
        ),
        title: Text( 
          article.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text("${article.category} • ${article.readTime}"),
        trailing: IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          color: isBookmarked ? Colors.blue : null,
          onPressed: onBookmarkToggle,
        ),
      ),
    );
  }
}
