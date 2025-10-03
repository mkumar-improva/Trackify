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
    this.initialConfigs = const <AccountConfig>[],
  });

  final List<String> senders;
  final Future<void> Function(List<AccountConfig>) onComplete;
  final VoidCallback? onSkip;
  final List<AccountConfig> initialConfigs;

  @override
  State<AccountOnboardingScreen> createState() => _AccountOnboardingScreenState();
}

class _AccountOnboardingScreenState extends State<AccountOnboardingScreen> {
  final List<_AccountFormData> _forms = [];
  final Map<String, String> _senderOwners = {};
  int _idSeed = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfigs.isEmpty) {
      _forms.add(_AccountFormData(id: _generateId()));
    } else {
      for (final config in widget.initialConfigs) {
        final form = _AccountFormData(
          id: config.id,
          initialName: config.name,
          initialSuffix: config.accountSuffix,
          initialSenders: config.senders,
        );
        _forms.add(form);
      }
      _rebuildSenderOwners();
    }
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
      _rebuildSenderOwners();
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
      _senderOwners.removeWhere((_, ownerId) => ownerId == form.id);
      form.dispose();
      _rebuildSenderOwners();
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

      final previousOwnerId = _senderOwners[sender];
      if (previousOwnerId != null) {
        final previousFormIndex =
            _forms.indexWhere((existing) => existing.id == previousOwnerId);
        if (previousFormIndex != -1 && previousFormIndex != accountIndex) {
          final previousForm = _forms[previousFormIndex];
          previousForm.selectedSenders.remove(sender);
        }
      }

      form.selectedSenders.add(sender);
      _senderOwners[sender] = form.id;
    });
  }

  void _rebuildSenderOwners() {
    _senderOwners
      ..clear()
      ..addEntries(
        _forms.asMap().entries.expand((entry) {
          final form = entry.value;
          return form.selectedSenders.map((sender) => MapEntry(sender, form.id));
        }),
      );
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
    final isEditing = widget.initialConfigs.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF174EA6), Color(0xFF4285F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isEditing ? 'Manage your bank accounts' : 'Link your bank accounts',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing
                      ? 'Update account names or assign additional SMS senders so your insights stay accurate.'
                      : 'Choose the SMS senders that belong to each bank account. Trackify Pay will group alerts just like Google Pay.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (widget.senders.isEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.sms_failed_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We could not find any transaction alerts yet. You can skip this step and add accounts later.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _forms.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _AccountCard(
                index: i,
                form: _forms[i],
                allSenders: widget.senders,
                onToggleSender: _toggleSender,
                onRemove: () => _removeAccount(i),
                canRemove: _forms.length > 1,
              ),
            ),
          FilledButton.tonalIcon(
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
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All senders assigned to accounts.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
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
                : Text(
                    widget.senders.isEmpty
                        ? 'Skip for now'
                        : isEditing
                            ? 'Save accounts'
                            : 'Save & continue',
                  ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.65),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account ${widget.index + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  tooltip: 'Remove account',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.form.nameController,
            decoration: const InputDecoration(
              labelText: 'Account name',
              hintText: 'e.g. HDFC Savings',
              filled: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.form.suffixController,
            decoration: const InputDecoration(
              labelText: 'Last 4 digits (optional)',
              hintText: '1234',
              counterText: '',
              filled: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Assign SMS senders',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
                filled: true,
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
    );
  }
}

class _AccountFormData {
  _AccountFormData({
    required this.id,
    String? initialName,
    String? initialSuffix,
    Set<String>? initialSenders,
  })  : nameController = TextEditingController(text: initialName ?? ''),
        suffixController = TextEditingController(text: initialSuffix ?? '') {
    if (initialSenders != null) {
      selectedSenders.addAll(initialSenders);
    }
  }

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
