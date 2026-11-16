import 'package:flutter/material.dart';

import '../../core/session.dart';
import '../../l10n/l10n.dart';
import '../../widgets/key_tile.dart';
import '../../widgets/ui.dart';
import 'contact_details_screen.dart';
import 'import_screen.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final all = Session.instance.contacts;
        final q = _q.toLowerCase();
        final list = all
            .where((k) => q.isEmpty || k.uids.any((u) => u.toLowerCase().contains(q)) || k.fp.toLowerCase().contains(q.replaceAll(' ', '')))
            .toList()
          ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'addContact',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l.addContact),
            onPressed: () => showImportSources(context),
          ),
          body: all.isEmpty
              ? EmptyState(icon: Icons.people_rounded, title: l.noContactsTitle, message: l.noContactsBody)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    PageTitle(l.contacts),
                    TextField(
                      decoration: InputDecoration(hintText: l.searchContacts, prefixIcon: const Icon(Icons.search_rounded)),
                      onChanged: (v) => setState(() => _q = v.trim()),
                    ),
                    SectionLabel(
                      l.contactsCount(list.length),
                      trailing: IconButton(
                        tooltip: l.scanQr,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        onPressed: () => scanAndHandle(context),
                      ),
                    ),
                    for (final k in list) ...[
                      KeyTile(
                        k: k,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailsScreen(fp: k.fp))),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
