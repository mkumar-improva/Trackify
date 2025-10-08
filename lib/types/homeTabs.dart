class HomeTabs {
  final String name;
  final String value;
  const HomeTabs(this.name, this.value);
}

const List<HomeTabs> homeTabs = [
  HomeTabs('Transactions', 'transactions'),
  HomeTabs('Trends', 'trends'),
];