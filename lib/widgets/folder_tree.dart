import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../models/book.dart';

class FolderTree extends StatelessWidget {
  final Folder rootFolder;
  final Function(Folder) onFolderSelected;
  final Function(Book, Folder) onBookDropped;

  const FolderTree({
    Key? key,
    required this.rootFolder,
    required this.onFolderSelected,
    required this.onBookDropped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: rootFolder,
      child: _buildFolderTree(rootFolder),
    );
  }

  Widget _buildFolderTree(Folder folder) {
    return Consumer<Folder>(
      builder: (context, folder, child) {
        return DragTarget<Book>(
          builder: (context, candidateData, rejectedData) {
            return ExpansionTile(
              title: Text(folder.name),
              children: [
                ...folder.subfolders.map((subfolder) => _buildFolderTree(subfolder)),
              ],
              onExpansionChanged: (expanded) {
                if (expanded) {
                  onFolderSelected(folder);
                }
              },
            );
          },
          onAccept: (book) {
            onBookDropped(book, folder);
          },
        );
      },
    );
  }
}