import 'package:flutter/material.dart';
import '../models/yapp.dart';

class YappListItem extends StatelessWidget {
  final Yapp yapp;
  final bool isSelected;
  final VoidCallback onPlay;
  final VoidCallback onShare;

  const YappListItem({
    Key? key,
    required this.yapp,
    required this.isSelected,
    required this.onPlay,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
      child: ListTile(
        title: Text(yapp.name),
        subtitle: Text('Created on: ${yapp.creationDate.toLocal()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onPlay,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onShare,
            ),
          ],
        ),
      ),
    );
  }
}
