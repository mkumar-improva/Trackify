import 'package:flutter/material.dart';

class SenderPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final Set<String> initiallySelected;

  const SenderPickerSheet({
    required this.title,
    required this.items,
    required this.initiallySelected,
  });

  @override
  State<SenderPickerSheet> createState() => _SenderPickerSheetState();
}

class _SenderPickerSheetState extends State<SenderPickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected}.intersection(widget.items.toSet());
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((s) => s.toLowerCase().contains(q)).toList();
  }

  bool get _allSelected => _selected.length == widget.items.length && widget.items.isNotEmpty;
  bool get _noneSelected => _selected.isEmpty;
  bool get _someSelected => !_noneSelected && !_allSelected;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected = widget.items.toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  child: Text('Done (${_selected.length})'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search senders',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Select all (tri-state)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CheckboxListTile(
              dense: true,
              title: Text('Select all (${widget.items.length})'),
              value: _allSelected ? true : (_someSelected ? null : false),
              tristate: true,
              onChanged: (_) => _toggleAll(),
            ),
          ),

          const Divider(height: 0),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No senders'))
                : ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final sender = _filtered[i];
                final checked = _selected.contains(sender);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                  child: CheckboxListTile(
                    title: Text(sender),
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(sender);
                        } else {
                          _selected.remove(sender);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selected.clear()),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                Text('${_selected.length} selected'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
