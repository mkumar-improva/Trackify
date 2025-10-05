import 'package:flutter/material.dart';

class TrackifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  const TrackifyAppBar({super.key, required this.titleText});



  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(onPressed: (){}, icon: Icon(Icons.logout, size: 20,), tooltip: 'Logout',)
      ],
    );
  }
}
