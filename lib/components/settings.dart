import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/components/card/card_manager.dart';
import 'package:trackify/theme/app_theme.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool autoSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    getAutoSyncPreference().then((value) {
      setState(() {
        autoSyncEnabled = value;
      });
    });
  }

  Future<bool> getAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_sync_enabled') ?? false;
  }

  Future<void> setAutoSyncPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', value);
  }

  onAutoSyncChanged(bool value) {
    setState(() {
      autoSyncEnabled = value;
    });
    setAutoSyncPreference(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Manage Cards'),
          subtitle: const Text('Add, remove, or edit your card details'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.credit_card, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageCardsScreen()),
            );
          },
        ),
        Divider(),
        ListTile(
          title: Text('Profile'),
          subtitle: Text('Manage your profile settings'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.person, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        Divider(),
        ListTile(
          title: Text('Notifications'),
          subtitle: Text('Manage your notification preferences'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.notifications, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        Divider(),
        ListTile(
          title: Text('Privacy & Security'),
          subtitle: Text('Manage your privacy and security settings'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.lock, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        Divider(),
        ListTile(
          title: Text('Auto SMS sync'),
          subtitle: Text('Automatically sync SMS for transaction data'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.sync, color: Colors.black87),
          ),
          trailing: Switch(
            value: autoSyncEnabled,
            onChanged: onAutoSyncChanged,
          ),
        ),
        Divider(),
        ListTile(
          title: Text('About'),
          subtitle: Text('Learn more about this app'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.info, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        Divider(),
        ListTile(
          title: Text('Help & Support'),
          subtitle: Text('Get help and support'),
          leading: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD5D4D4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6), // inner spacing
            child: const Icon(Icons.help, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }
}
