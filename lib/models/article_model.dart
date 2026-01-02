class Article {
  final String id;
  final String title;
  final String content;
  final String category;
  final String readTime;
  final String author;
  final DateTime publishDate;
  final String imageUrl;
  final List<String> tags;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.readTime,
    required this.author,
    required this.publishDate,
    required this.imageUrl,
    required this.tags,
  });
}