import 'package:flutter/foundation.dart';
import 'book.dart';

class Folder with ChangeNotifier {
  String id;
  String name;
  List<Folder> subfolders;
  List<Book> books;
  Folder? parent;

  Folder({
    required this.id,
    required this.name,
    this.subfolders = const [],
    this.books = const [],
    this.parent,
  });

  void addSubfolder(Folder subfolder) {
    subfolders.add(subfolder);
    subfolder.parent = this;
    notifyListeners();
  }

  void removeSubfolder(Folder subfolder) {
    subfolders.remove(subfolder);
    notifyListeners();
  }

  void addBook(Book book) {
    books.add(book);
    notifyListeners();
  }

  void removeBook(Book book) {
    books.remove(book);
    notifyListeners();
  }

  void rename(String newName) {
    name = newName;
    notifyListeners();
  }
}