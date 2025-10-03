import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../types/account_config.dart';

class AccountOnboardingScreen extends StatefulWidget {
  const AccountOnboardingScreen({
    super.key,
    required this.senders,
    required this.onComplete,
    this.onSkip,
  });

  final List<String> senders;
  final Future<void> Function(List<AccountConfig>) onComplete;
  final VoidCallback? onSkip;

  @override
  State<AccountOnboardingScreen> createState() => _AccountOnboardingScreenState();
}

class _AccountOnboardingScreenState extends State<AccountOnboardingScreen> {
  final List<_AccountFormData> _forms = [];
  final Map<String, int> _senderOwners = {};
  int _idSeed = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _forms.add(_AccountFormData(id: _generateId()));
  }

  @override
  void didUpdateWidget(covariant AccountOnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.senders.toSet(), widget.senders.toSet())) {
      final Set<String> currentSenders = widget.senders.toSet();
      _senderOwners.removeWhere((sender, _) => !currentSenders.contains(sender));
      for (final form in _forms) {
        form.selectedSenders.removeWhere((sender) => !currentSenders.contains(sender));
      }
    }
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    super.dispose();
  }

  String _generateId() {
    _idSeed += 1;
    return 'acc_${DateTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  void _addAccount() {
    setState(() {
      _forms.add(_AccountFormData(id: _generateId()));
    });
  }

  void _removeAccount(int index) {
    if (_forms.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one account to continue.')),
      );
      return;
    }

    setState(() {
      final form = _forms.removeAt(index);
      for (final sender in form.selectedSenders) {
        _senderOwners.remove(sender);
      }
      form.dispose();
    });
  }

  void _toggleSender(int accountIndex, String sender) {
    setState(() {
      final form = _forms[accountIndex];
      if (form.selectedSenders.contains(sender)) {
        form.selectedSenders.remove(sender);
        _senderOwners.remove(sender);
        return;
      }

      final previousOwner = _senderOwners[sender];
      if (previousOwner != null && previousOwner != accountIndex) {
        final previousForm = _forms[previousOwner];
        previousForm.selectedSenders.remove(sender);
      }

      form.selectedSenders.add(sender);
      _senderOwners[sender] = accountIndex;
    });
  }

  Future<void> _handleSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final activeForms = _forms.where((form) => form.hasData).toList();

    if (widget.senders.isNotEmpty && activeForms.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add at least one account and assign senders.')),
      );
      return;
    }

    final List<AccountConfig> configs = [];
    for (final form in activeForms) {
      final name = form.nameController.text.trim();
      final suffix = form.suffixController.text.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Give each account a name.')),
        );
        return;
      }

      if (form.selectedSenders.isEmpty && widget.senders.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('Assign at least one sender to "$name".')),
        );
        return;
      }

      configs.add(
        AccountConfig(
          id: form.id,
          name: name,
          accountSuffix: suffix.isEmpty ? null : suffix,
          senders: Set<String>.of(form.selectedSenders),
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      await widget.onComplete(configs);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<String> get _unassignedSenders {
    return widget.senders
        .where((sender) => !_senderOwners.containsKey(sender))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unassigned = _unassignedSenders;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link your bank accounts',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the SMS senders that correspond to each bank account. We use this to group and analyse your transactions.',
            style: theme.textTheme.bodyMedium,
          ),
          if (widget.senders.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.sms_failed_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We could not find any transaction alerts yet. You can skip this step and revisit from settings later.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          for (var i = 0; i < _forms.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AccountCard(
                index: i,
                form: _forms[i],
                allSenders: widget.senders,
                onToggleSender: _toggleSender,
                onRemove: () => _removeAccount(i),
                canRemove: _forms.length > 1,
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add),
            label: const Text('Add another account'),
          ),
          if (widget.senders.isNotEmpty) ...[
            const SizedBox(height: 24),
            if (unassigned.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: Text('${unassigned.length} sender(s) not assigned'),
                  ),
                  ...unassigned.map((sender) => Chip(label: Text(sender))),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'All senders assigned to accounts.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving
                ? null
                : widget.senders.isEmpty && widget.onSkip != null
                    ? widget.onSkip
                    : () => _handleSubmit(),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.senders.isEmpty ? 'Skip for now' : 'Save & continue'),
          ),
          if (widget.senders.isNotEmpty && widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip for now'),
            ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({
    required this.index,
    required this.form,
    required this.allSenders,
    required this.onToggleSender,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final _AccountFormData form;
  final List<String> allSenders;
  final void Function(int index, String sender) onToggleSender;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  String _searchQuery = '';

  List<String> get _filteredSenders {
    if (_searchQuery.isEmpty) {
      return widget.allSenders;
    }

    final query = _searchQuery.toLowerCase();
    return widget.allSenders
        .where((sender) => sender.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredSenders = _filteredSenders;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account ${widget.index + 1}',
                  style: theme.textTheme.titleMedium,
                ),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Remove account',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.form.nameController,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. HDFC Savings',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.form.suffixController,
              decoration: const InputDecoration(
                labelText: 'Last 4 digits (optional)',
                hintText: '1234',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Assign SMS senders',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (widget.allSenders.isEmpty)
              Text(
                'Senders will appear here after we detect new SMS alerts.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search senders',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (filteredSenders.isEmpty)
                Text(
                  'No senders match your search.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredSenders
                      .map(
                        (sender) => FilterChip(
                          label: Text(sender),
                          selected: widget.form.selectedSenders.contains(sender),
                          onSelected: (_) =>
                              widget.onToggleSender(widget.index, sender),
                        ),
                      )
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountFormData {
  _AccountFormData({required this.id})
      : nameController = TextEditingController(),
        suffixController = TextEditingController();

  final String id;
  final TextEditingController nameController;
  final TextEditingController suffixController;
  final Set<String> selectedSenders = <String>{};

  bool get hasData {
    return nameController.text.trim().isNotEmpty ||
        suffixController.text.trim().isNotEmpty ||
        selectedSenders.isNotEmpty;
  }

  void dispose() {
    nameController.dispose();
    suffixController.dispose();
  }
}
