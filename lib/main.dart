import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/book_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BookService bookService = BookService();

    return MaterialApp(
      title: 'Book Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(bookService: bookService),
    );
  }
}