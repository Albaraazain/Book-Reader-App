import 'dart:io';

import 'package:flutter/material.dart';
import '../models/book.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookTap;
  final Function(Book, Offset) onDragStarted;
  final Function(Book) onDragEnd;

  const BookGrid({
    Key? key,
    required this.books,
    required this.onBookTap,
    required this.onDragStarted,
    required this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return LongPressDraggable<Book>(
          data: book,
          feedback: _buildBookCover(context, book, size: 100),
          childWhenDragging: _buildBookCover(context, book, opacity: 0.5),
          onDragStarted: () => onDragStarted(book, Offset.zero),
          onDragEnd: (_) => onDragEnd(book),
          child: GestureDetector(
            onTap: () => onBookTap(book),
            child: _buildBookCover(context, book),
          ),
        );
      },
    );
  }

  Widget _buildBookCover(BuildContext context, Book book, {double? size, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: book.coverImagePath != null
                  ? Image.file(File(book.coverImagePath!), fit: BoxFit.cover)
                  : Container(color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(book.author, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}