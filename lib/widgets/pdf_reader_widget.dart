import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';
import '../services/book_service.dart'; // Add this line

class PdfReaderWidget extends StatefulWidget {
  final Book book;
  final BookService bookService; // Add this line

  const PdfReaderWidget({Key? key, required this.book, required this.bookService}) : super(key: key);

  @override
  _PdfReaderWidgetState createState() => _PdfReaderWidgetState();
}

class _PdfReaderWidgetState extends State<PdfReaderWidget> {
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    super.initState();
  }

  void _showContextMenu(
      BuildContext context, PdfTextSelectionChangedDetails details) {
    // ... (keep the existing _showContextMenu implementation)
  }

  void _performSearch() {
    final String searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _searchResult = _pdfViewerController.searchText(searchQuery);
      _searchResult.addListener(() {
        if (_searchResult.hasResult) {
          setState(() {});
        }
      });
    }
  }

  void _addBookmark() {
    final currentPage = _pdfViewerController.pageNumber;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Bookmark'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Enter bookmark description'),
          onSubmitted: (description) {
            Navigator.of(context).pop();
            widget.book.addBookmark(currentPage, description);
            widget.bookService.updateBookMetadata(widget.book);
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              Navigator.of(context).pop();
              // Add bookmark logic here
            },
          ),
        ],
      ),
    );
  }

  void _showBookmarks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bookmarks'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: widget.book.sortedBookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = widget.book.sortedBookmarks[index];
              return ListTile(
                title: Text(
                    'Page ${bookmark.pageNumber}: ${bookmark.description}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pdfViewerController.jumpToPage(bookmark.pageNumber);
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    widget.book.removeBookmark(bookmark.pageNumber);
                    widget.bookService.updateBookMetadata(widget.book);
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Search'),
                  content: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: 'Enter search term'),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text('Search'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _performSearch();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.bookmark_add),
            onPressed: _addBookmark,
          ),
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: _showBookmarks,
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.book.filePath),
            controller: _pdfViewerController,
            key: _pdfViewerKey,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            scrollDirection: PdfScrollDirection.vertical,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null &&
                  details.selectedText!.isNotEmpty) {
                _showContextMenu(context, details);
              } else {
                _overlayEntry?.remove();
                _overlayEntry = null;
              }
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              _pdfViewerController.jumpToPage(widget.book.lastPageRead);
            },
            onPageChanged: (PdfPageChangedDetails details) {
              widget.book.updateLastPageRead(details.newPageNumber);
              widget.bookService.updateBookMetadata(widget.book);
            },
            enableDocumentLinkAnnotation: true,
          ),
          if (_isSearching && _searchResult.hasResult)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_searchResult.currentInstanceIndex + 1} of ${_searchResult.totalInstanceCount}',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () {
                        _searchResult.previousInstance();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward, color: Colors.white),
                      onPressed: () {
                        _searchResult.nextInstance();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _searchResult.clear();
                          _isSearching = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}
