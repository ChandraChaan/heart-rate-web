import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../labels.dart';
import '../monitor_controller.dart';

/// Shown until a strap or the demo is connected.
class ConnectPanel extends ConsumerWidget {
  const ConnectPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(monitorProvider);
    final supported = ref.watch(bluetoothSupportedProvider);
    final connectingDemo = switch (state) {
      MonitorConnecting(:final simulated) => simulated,
      _ => null,
    };
    final connecting = connectingDemo != null;
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final failure = state is MonitorIdle ? state.failure : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.monitor_heart_outlined,
          size: 64,
          color: theme.colorScheme.primary,
          semanticLabel: l10n.appTitle,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.connectTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.connectBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (!supported) ...[
          const _UnsupportedNotice(),
          const SizedBox(height: 16),
        ],
        if (failure != null) ...[
          _FailureNotice(message: l10n.failureMessage(failure)),
          const SizedBox(height: 16),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (supported)
              FilledButton.icon(
                key: const Key('connect'),
                onPressed: connecting
                    ? null
                    : () => ref.read(monitorProvider.notifier).connect(),
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(l10n.connectButton),
              ),
            OutlinedButton.icon(
              key: const Key('demo'),
              onPressed: connecting
                  ? null
                  : () => ref.read(monitorProvider.notifier).startDemo(),
              icon: const Icon(Icons.science_outlined),
              label: Text(l10n.demoButton),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (connecting) ...[
          const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connectingDemo ? l10n.connectingDemo : l10n.connectingStrap,
            textAlign: TextAlign.center,
          ),
        ] else ...[
          if (supported)
            Text(
              l10n.connectTip,
              textAlign: TextAlign.center,
              style: hintStyle,
            ),
          const SizedBox(height: 4),
          Text(l10n.demoHint, textAlign: TextAlign.center, style: hintStyle),
        ],
        const SizedBox(height: 32),
        Text(
          l10n.privacyNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _UnsupportedNotice extends StatelessWidget {
  const _UnsupportedNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('unsupported'),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.unsupportedTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unsupportedBody,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('failure'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
