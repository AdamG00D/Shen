import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/session.dart';
import 'core/settings.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/lock/lock_screen.dart';
import 'features/lock/setup_screen.dart';
import 'l10n/l10n.dart';
import 'widgets/focus_guard.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class ShenApp extends StatefulWidget {
  const ShenApp({super.key});

  @override
  State<ShenApp> createState() => _ShenAppState();
}

class _ShenAppState extends State<ShenApp> {
  final _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_changed);
    // لما الخزنة تتقفل: كل الشاشات المفتوحة تتقفل وترجع لشاشة القفل
    Session.instance.onLocked = () => rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _settings.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      onGenerateTitle: (c) => c.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: _settings.themeMode,
      locale: _settings.language == null ? null : Locale(_settings.language!),
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, _) {
        final l = L10n.pick(_settings.language, device);
        L10n.use(l);
        return l;
      },
      navigatorObservers: [FocusGuard()],
      home: const Gate(),
    );
  }
}

/// بيختار الشاشة حسب حالة الخزنة.
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) => switch (Session.instance.phase) {
        Phase.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
        Phase.setup => const SetupScreen(),
        Phase.locked => const LockScreen(),
        Phase.unlocked => const HomeScreen(),
      },
    );
  }
}
