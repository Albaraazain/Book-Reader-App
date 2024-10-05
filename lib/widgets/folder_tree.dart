import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';

class FolderTree extends StatelessWidget {
  final Folder rootFolder;

  const FolderTree({Key? key, required this.rootFolder}) : super(key: key);

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
        return ExpansionTile(
          title: Text(folder.name),
          children: [
            ...folder.subfolders.map((subfolder) => _buildFolderTree(subfolder)),
            ...folder.books.map((book) => ListTile(title: Text(book.title))),
          ],
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _showAddDialog(context, folder),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showRenameDialog(context, folder),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteFolder(context, folder),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, Folder parentFolder) {
    showDialog(
      context: context,
      builder: (context) {
        String newFolderName = '';
        return AlertDialog(
          title: Text('Add New Folder'),
          content: TextField(
            onChanged: (value) => newFolderName = value,
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (newFolderName.isNotEmpty) {
                  parentFolder.addSubfolder(Folder(
                    id: DateTime.now().toString(),
                    name: newFolderName,
                  ));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = folder.name;
        return AlertDialog(
          title: Text('Rename Folder'),
          content: TextField(
            onChanged: (value) => newName = value,
            decoration: InputDecoration(hintText: 'New Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () {
                if (newName.isNotEmpty) {
                  folder.rename(newName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteFolder(BuildContext context, Folder folder) {
    if (folder.parent != null) {
      folder.parent!.removeSubfolder(folder);
    } else {
      // Handle root folder deletion (if allowed)
    }
  }
}