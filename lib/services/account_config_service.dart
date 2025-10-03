import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../types/account_config.dart';

class AccountConfigService {
  static const _storageKey = 'account_configs_v1';

  Future<List<AccountConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <AccountConfig>[];
    }

    try {
      final data = jsonDecode(raw);
      if (data is! List) return const <AccountConfig>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AccountConfig.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <AccountConfig>[];
    }
  }

  Future<void> saveConfigs(List<AccountConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
