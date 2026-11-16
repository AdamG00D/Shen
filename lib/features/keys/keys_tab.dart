import 'package:flutter/material.dart';

import '../../core/session.dart';
import '../../l10n/l10n.dart';
import '../../widgets/key_tile.dart';
import '../../widgets/ui.dart';
import '../contacts/import_screen.dart';
import 'generate_key_screen.dart';
import 'key_details_screen.dart';

class KeysTab extends StatelessWidget {
  const KeysTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final keys = Session.instance.keys;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'newKey',
            icon: const Icon(Icons.add_rounded),
            label: Text(l.newKey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateKeyScreen())),
          ),
          body: keys.isEmpty
              ? EmptyState(
                  icon: Icons.vpn_key_rounded,
                  title: l.noKeysTitle,
                  message: l.noKeysBody,
                  action: SizedBox(
                    width: 240,
                    child: SecondaryButton(
                      label: l.importKey,
                      icon: Icons.download_rounded,
                      onPressed: () => showImportSources(context),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: Session.instance.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    children: [
                      SectionLabel(
                        l.myKeysCount(keys.length),
                        trailing: TextButton.icon(
                          onPressed: () => showImportSources(context),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(l.importKey),
                        ),
                      ),
                      for (final k in keys) ...[
                        KeyTile(
                          k: k,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KeyDetailsScreen(fp: k.fp))),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
