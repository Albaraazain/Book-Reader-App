import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/pdf_reader_widget.dart';

class ReaderScreen extends StatelessWidget {
  final Book book;
  final BookService bookService;

  const ReaderScreen({Key? key, required this.book, required this.bookService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdfReaderWidget(book: book, bookService: bookService),
    );
  }
}