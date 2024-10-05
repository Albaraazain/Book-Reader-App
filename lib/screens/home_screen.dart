import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/book.dart';
import '../widgets/folder_tree.dart';
import '../widgets/book_grid.dart';
import '../services/book_service.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  final BookService bookService;

  const HomeScreen({Key? key, required this.bookService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Folder rootFolder;
  Folder? selectedFolder;
  String searchQuery = '';
  bool isLoading = true;
  Book? draggedBook;

  @override
  void initState() {
    super.initState();
    rootFolder = Folder(id: 'root', name: 'My Library');
    selectedFolder = rootFolder;
    _loadLibrary();
  }
  
  Future<void> _loadLibrary() async {
    setState(() {
      isLoading = true;
    });

    final folders = await widget.bookService.getFolders();

    // Reconstruct folder hierarchy
    final Map<String, Folder> folderMap = {rootFolder.id: rootFolder};
    for (final folder in folders) {
      folderMap[folder.id] = folder;
    }

    for (final folder in folders) {
      final parentId = folder.parent?.id;
      if (parentId != null && folderMap.containsKey(parentId)) {
        folderMap[parentId]!.addSubfolder(folder);
      } else {
        rootFolder.addSubfolder(folder);
      }
    }

    // Load books for each folder
    for (final folder in folderMap.values) {
      final books = await widget.bookService.loadBooksInFolder(folder);
      folder.books = books;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Library'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _importBook,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Container(
                  width: 250,
                  child: FolderTree(
                    rootFolder: rootFolder,
                    onFolderSelected: (folder) {
                      setState(() {
                        selectedFolder = folder;
                      });
                    },
                    onBookDropped: (book, folder) {
                      _moveBook(book, folder);
                    },
                  ),
                ),
                VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: BookGrid(
                          books: _getFilteredBooks(),
                          onBookTap: _openBook,
                          onDragStarted: (book, offset) {
                            setState(() {
                              draggedBook = book;
                            });
                          },
                          onDragEnd: (book) {
                            setState(() {
                              draggedBook = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _moveBook(Book book, Folder targetFolder) async {
    if (selectedFolder != null && selectedFolder != targetFolder) {
      await widget.bookService.moveBook(book, selectedFolder!, targetFolder);
      setState(() {
        // Refresh the UI
      });
    }
  }

  List<Book> _getFilteredBooks() {
    if (searchQuery.isEmpty) {
      return selectedFolder?.books ?? [];
    } else {
      return widget.bookService.searchBooks(selectedFolder?.books ?? [], searchQuery);
    }
  }

  void _importBook() async {
    if (selectedFolder != null) {
      final Book? importedBook = await widget.bookService.importBook(selectedFolder!);
      if (importedBook != null) {
        setState(() {
          // Refresh the UI
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book "${importedBook.title}" imported successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a folder to import the book')),
      );
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book, bookService: widget.bookService),
      ),
    );
  }
}