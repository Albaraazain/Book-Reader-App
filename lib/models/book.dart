import 'package:flutter/foundation.dart';

class BookmarkEntry {
  final int pageNumber;
  final String description;

  BookmarkEntry({required this.pageNumber, required this.description});
}

class Book with ChangeNotifier {
  String id;
  String title;
  String author;
  String filePath;
  String? coverImagePath;
  List<String> tags;
  int lastPageRead;
  DateTime dateAdded;
  List<BookmarkEntry> bookmarks;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverImagePath,
    this.tags = const [],
    this.lastPageRead = 0,
    DateTime? dateAdded,
    this.bookmarks = const [],
  }) : this.dateAdded = dateAdded ?? DateTime.now();

  void updateMetadata({
    String? title,
    String? author,
    String? coverImagePath,
    List<String>? tags,
  }) {
    if (title != null) this.title = title;
    if (author != null) this.author = author;
    if (coverImagePath != null) this.coverImagePath = coverImagePath;
    if (tags != null) this.tags = tags;
    notifyListeners();
  }

  void updateLastPageRead(int page) {
    lastPageRead = page;
    notifyListeners();
  }

  void addBookmark(int pageNumber, String description) {
    bookmarks
        .add(BookmarkEntry(pageNumber: pageNumber, description: description));
    notifyListeners();
  }

  void removeBookmark(int pageNumber) {
    bookmarks.removeWhere((bookmark) => bookmark.pageNumber == pageNumber);
    notifyListeners();
  }

  BookmarkEntry? getBookmark(int pageNumber) {
  try {
    return bookmarks.firstWhere(
      (bookmark) => bookmark.pageNumber == pageNumber,
    );
  } catch (e) {
    return null;
  }
}

  List<BookmarkEntry> get sortedBookmarks {
    final sorted = List<BookmarkEntry>.from(bookmarks);
    sorted.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return sorted;
  }
}
