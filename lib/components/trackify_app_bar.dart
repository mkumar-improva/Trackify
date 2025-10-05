import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/screens/login_page_v2.dart';

class TrackifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  const TrackifyAppBar({super.key, required this.titleText});
  
  void _onLogoutPressed(BuildContext context) async {
    // Implement logout functionality here
    final pref = await SharedPreferences.getInstance();
    pref.setBool("isLoggedIn", false);
    // Navigate to login screen or perform other actions
    Navigator.pushReplacement(
      context,
    MaterialPageRoute(builder: (context) => LoginPage()),);
  }



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
        IconButton(onPressed: (){_onLogoutPressed(context);}, icon: Icon(Icons.logout, size: 20,), tooltip: 'Logout',)
      ],
    );
  }
}
