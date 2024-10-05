import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/folder.dart';
import 'database_helper.dart';

class BookService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> updateBookMetadata(Book book,
      {String? title,
      String? author,
      String? coverImagePath,
      List<String>? tags,
      List<BookmarkEntry>? bookmarks}) async {
    book.updateMetadata(
      title: title,
      author: author,
      coverImagePath: coverImagePath,
      tags: tags,
    );
    if (bookmarks != null) {
      book.bookmarks = bookmarks;
    }
    await _dbHelper.updateBook(book);
  }

  Future<void> updateLastPageRead(Book book, int lastPageRead) async {
    book.updateLastPageRead(lastPageRead);
    await _dbHelper.updateLastPageRead(book);
  }

  Future<Book?> importBook(Folder targetFolder) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String fileName = path.basename(file.path);
      final String bookTitle = path.basenameWithoutExtension(fileName);

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      final String newFilePath = path.join(appDocPath, 'books', fileName);

      // Create the books directory if it doesn't exist
      await Directory(path.dirname(newFilePath)).create(recursive: true);

      // Copy the file to the app's documents directory
      await file.copy(newFilePath);

      final Book newBook = Book(
        id: DateTime.now().toString(),
        title: bookTitle,
        author: 'Unknown', // You might want to extract this from PDF metadata
        filePath: newFilePath,
        dateAdded: DateTime.now(),
      );

      await _dbHelper.insertBook(newBook, targetFolder.id);
      targetFolder.addBook(newBook);

      return newBook;
    }

    return null; // User canceled the file picker
  }

  List<Book> searchBooks(List<Book> books, String query) {
    query = query.toLowerCase();
    return books
        .where((book) =>
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            book.tags.any((tag) => tag.toLowerCase().contains(query)))
        .toList();
  }

  Future<void> deleteBook(Book book, Folder folder) async {
    folder.removeBook(book);
    await _dbHelper.deleteBook(book.id);

    final File bookFile = File(book.filePath);
    if (await bookFile.exists()) {
      await bookFile.delete();
    }

    if (book.coverImagePath != null) {
      final File coverImageFile = File(book.coverImagePath!);
      if (await coverImageFile.exists()) {
        await coverImageFile.delete();
      }
    }
  }

  // getfolders
  Future<List<Folder>> getFolders() async {
    return await _dbHelper.getFolders();
  }

  Future<List<Book>> loadBooksInFolder(Folder folder) async {
    return await _dbHelper.getBooksInFolder(folder.id);
  }

  Future<void> moveBook(
      Book book, Folder sourceFolder, Folder targetFolder) async {
    sourceFolder.removeBook(book);
    targetFolder.addBook(book);
    await _dbHelper.updateBookFolder(book, targetFolder.id);
  }
}
