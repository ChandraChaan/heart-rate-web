import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/recorded_session.dart';
import 'session_detail_screen.dart';
import 'sessions_controller.dart';

/// The Sessions tab: everything recorded in this browser.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(sessionsProvider);
    return switch (sessions) {
      AsyncData(value: final sessions) when sessions.isEmpty => _Message(
        icon: Icons.history,
        title: l10n.sessionsEmptyTitle,
        body: l10n.sessionsEmptyBody,
      ),
      AsyncData(value: final sessions) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) => _SessionTile(
              key: ValueKey(sessions[index].id),
              session: sessions[index],
            ),
          ),
        ),
      ),
      AsyncError() => _Message(
        icon: Icons.error_outline,
        title: l10n.sessionsLoadError,
        action: FilledButton(
          onPressed: () => ref.invalidate(sessionsProvider),
          child: Text(l10n.retry),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session, super.key});

  final RecordedSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(sessionStatsProvider(session.id));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = DateFormat.yMMMEd(
      locale,
    ).add_Hm().format(session.startedAt.toLocal());
    return ListTile(
      leading: Icon(
        session.simulated ? Icons.science_outlined : Icons.monitor_heart,
      ),
      title: Text(start),
      subtitle: Text(
        l10n.sessionSubtitle(
          formatDuration(session.duration),
          stats?.averageBpm ?? 0,
          stats?.maxBpm ?? 0,
        ),
      ),
      trailing: session.simulated
          ? Chip(label: Text(l10n.simulatedBadge))
          : const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailScreen(sessionId: session.id),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = this.body;
    final action = this.action;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
