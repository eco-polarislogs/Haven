import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'struggle_selector.dart';
import '../../l10n/tx.dart';

/// Profil → "Mücadele alanlarım": alanları sonradan düzenleme.
class StrugglePickerScreen extends ConsumerStatefulWidget {
  const StrugglePickerScreen({super.key});

  @override
  ConsumerState<StrugglePickerScreen> createState() => _StrugglePickerScreenState();
}

class _StrugglePickerScreenState extends ConsumerState<StrugglePickerScreen> {
  late final Set<String> _initial = {...?ref.read(appUserProvider).value?.struggleIds};
  late final Set<String> _selected = {..._initial};

  void _save() {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    ref.read(repositoryProvider).saveStruggles(uid, _selected, previous: _initial);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tx('Mücadele alanlarım'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          StruggleSelector(
            selected: _selected,
            onToggle: (id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(onPressed: _selected.isEmpty ? null : _save, child: Text(tx('Kaydet'))),
        ),
      ),
    );
  }
}
