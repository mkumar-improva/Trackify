class AccountConfig {
  AccountConfig({
    required this.id,
    required this.name,
    required Set<String> senders,
    this.accountSuffix,
  }) : senders = Set.unmodifiable(senders);

  factory AccountConfig.fromJson(Map<String, dynamic> json) {
    final sendersJson = json['senders'];
    final sendersList = sendersJson is List
        ? sendersJson.whereType<String>().toSet()
        : <String>{};
    return AccountConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Account',
      accountSuffix: json['accountSuffix'] as String?,
      senders: sendersList,
    );
  }

  final String id;
  final String name;
  final Set<String> senders;
  final String? accountSuffix;

  AccountConfig copyWith({
    String? id,
    String? name,
    Set<String>? senders,
    String? accountSuffix,
  }) {
    return AccountConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      senders: senders ?? this.senders,
      accountSuffix: accountSuffix ?? this.accountSuffix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountSuffix': accountSuffix,
      'senders': senders.toList(),
    };
  }

  bool matchesSender(String sender) => senders.contains(sender);
}
