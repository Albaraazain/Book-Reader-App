import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/folder.dart';
import '../models/book.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('book_library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 2, // Increment the version number
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ));
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE folders(
      id TEXT PRIMARY KEY,
      name TEXT,
      parentId TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE books(
      id TEXT PRIMARY KEY,
      title TEXT,
      author TEXT,
      filePath TEXT,
      coverImagePath TEXT,
      lastPageRead INTEGER,
      dateAdded TEXT,
      folderId TEXT,
      FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE book_tags(
      bookId TEXT,
      tag TEXT,
      PRIMARY KEY (bookId, tag),
      FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE bookmarks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId TEXT,
      pageNumber INTEGER,
      description TEXT,
      FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
    )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT,
        pageNumber INTEGER,
        description TEXT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
      ''');
    }
  }

  Future<void> insertFolder(Folder folder) async {
    final db = await database;
    await db.insert('folders', {
      'id': folder.id,
      'name': folder.name,
      'parentId': folder.parent?.id,
    });
  }

  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(
      'folders',
      {
        'name': folder.name,
        'parentId': folder.parent?.id,
      },
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }
  Future<void> insertBook(Book book, String folderId) async {
    final db = await database;
    await db.insert('books', {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'filePath': book.filePath,
      'coverImagePath': book.coverImagePath,
      'lastPageRead': book.lastPageRead,
      'dateAdded': book.dateAdded.toIso8601String(),
      'folderId': folderId,
    });

    for (final tag in book.tags) {
      await db.insert('book_tags', {
        'bookId': book.id,
        'tag': tag,
      });
    }

    for (final bookmark in book.bookmarks) {
      await db.insert('bookmarks', {
        'bookId': book.id,
        'pageNumber': bookmark.pageNumber,
        'description': bookmark.description,
      });
    }
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      {
        'title': book.title,
        'author': book.author,
        'filePath': book.filePath,
        'coverImagePath': book.coverImagePath,
        'lastPageRead': book.lastPageRead,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );

    await db.delete('book_tags', where: 'bookId = ?', whereArgs: [book.id]);
    for (final tag in book.tags) {
      await db.insert('book_tags', {
        'bookId': book.id,
        'tag': tag,
      });
    }

    await db.delete('bookmarks', where: 'bookId = ?', whereArgs: [book.id]);
    for (final bookmark in book.bookmarks) {
      await db.insert('bookmarks', {
        'bookId': book.id,
        'pageNumber': bookmark.pageNumber,
        'description': bookmark.description,
      });
    }
  }

  Future<void> updateLastPageRead(Book book) async {
    final db = await database;
    await db.update(
      'books',
      {'lastPageRead': book.lastPageRead},
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> updateBookFolder(Book book, String folderId) async {
    final db = await database;
    await db.update(
      'books',
      {'folderId': folderId},
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');

    return Future.wait(maps.map((map) async {
      final List<Map<String, dynamic>> subfolderMaps = await db.query(
        'folders',
        where: 'parentId = ?',
        whereArgs: [map['id']],
      );

      final List<Folder> subfolders = subfolderMaps
          .map((subfolderMap) => Folder(
                id: subfolderMap['id'],
                name: subfolderMap['name'],
              ))
          .toList();

      return Folder(
        id: map['id'],
        name: map['name'],
        subfolders: subfolders,
      );
    }).toList());
  }


  Future<void> deleteFolder(String folderId) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }

  Future<List<Book>> getBooksInFolder(String folderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );

    return Future.wait(maps.map((map) async {
      final List<Map<String, dynamic>> tagMaps = await db.query(
        'book_tags',
        where: 'bookId = ?',
        whereArgs: [map['id']],
      );

      final List<String> tags = tagMaps.map((tagMap) => tagMap['tag'] as String).toList();

      final List<Map<String, dynamic>> bookmarkMaps = await db.query(
        'bookmarks',
        where: 'bookId = ?',
        whereArgs: [map['id']],
      );

      final List<BookmarkEntry> bookmarks = bookmarkMaps
          .map((bookmarkMap) => BookmarkEntry(
                pageNumber: bookmarkMap['pageNumber'] as int,
                description: bookmarkMap['description'] as String,
              ))
          .toList();

      return Book(
        id: map['id'],
        title: map['title'],
        author: map['author'],
        filePath: map['filePath'],
        coverImagePath: map['coverImagePath'],
        lastPageRead: map['lastPageRead'],
        dateAdded: DateTime.parse(map['dateAdded']),
        tags: tags,
        bookmarks: bookmarks,
      );
    }).toList());
  }
}