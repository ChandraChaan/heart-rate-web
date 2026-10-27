import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import 'core/theme.dart';
import 'features/monitor/presentation/live_screen.dart';
import 'features/monitor/presentation/widgets/zone_settings_dialog.dart';
import 'features/sessions/presentation/sessions_screen.dart';
import 'l10n/app_localizations.dart';

class HeartRateApp extends StatelessWidget {
  const HeartRateApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    home: const HomeShell(),
  );
}

/// Live and Sessions tabs: a bottom bar on phones, a rail on wide screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static final _sourceCode = Uri.parse(
    'https://github.com/ChandraChaan/heart-rate-web',
  );

  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.monitor_heart_outlined, Icons.monitor_heart, l10n.navLive),
      (Icons.history_outlined, Icons.history, l10n.navSessions),
    ];
    final body = IndexedStack(
      index: _tab,
      children: const [LiveScreen(), SessionsScreen()],
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('zone-settings'),
            tooltip: l10n.zoneSettingsTooltip,
            icon: const Icon(Icons.tune),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const ZoneSettingsDialog(),
            ),
          ),
          Link(
            uri: _sourceCode,
            target: LinkTarget.blank,
            builder: (context, followLink) => IconButton(
              tooltip: l10n.sourceCodeTooltip,
              icon: const Icon(Icons.code),
              onPressed: followLink,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (tab) => setState(() => _tab = tab),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icon, selected, label) in destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (tab) => setState(() => _tab = tab),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
    );
  }
}
