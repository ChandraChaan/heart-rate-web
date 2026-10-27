import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/heart_rate_zones.dart';
import '../labels.dart';
import '../zone_settings_controller.dart';

/// Age and optional measured max HR, with a preview of the zones.
class ZoneSettingsDialog extends ConsumerStatefulWidget {
  const ZoneSettingsDialog({super.key});

  @override
  ConsumerState<ZoneSettingsDialog> createState() => _ZoneSettingsDialogState();
}

class _ZoneSettingsDialogState extends ConsumerState<ZoneSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _maxHr;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(zoneSettingsProvider);
    _age = TextEditingController(text: '${settings.age}');
    _maxHr = TextEditingController(
      text: settings.measuredMaxHr?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _maxHr.dispose();
    super.dispose();
  }

  /// The settings the fields describe, or null while they're invalid.
  ZoneSettings? get _entered {
    final age = int.tryParse(_age.text);
    if (age == null || age < ZoneSettings.minAge || age > ZoneSettings.maxAge) {
      return null;
    }
    final maxHrText = _maxHr.text.trim();
    if (maxHrText.isEmpty) return ZoneSettings(age: age);
    final maxHr = int.tryParse(maxHrText);
    if (maxHr == null ||
        maxHr < ZoneSettings.minMaxHr ||
        maxHr > ZoneSettings.maxMaxHr) {
      return null;
    }
    return ZoneSettings(age: age, measuredMaxHr: maxHr);
  }

  Future<void> _save() async {
    final settings = _entered;
    if (!_formKey.currentState!.validate() || settings == null) return;
    await ref.read(zoneSettingsProvider.notifier).save(settings);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(zoneSettingsProvider);
    final preview = _entered ?? saved;
    final zones = HeartRateZones(preview.maxHr);
    final zoneColors = ZoneColors.fromContext(context);

    return AlertDialog(
      title: Text(l10n.zoneSettingsTitle),
      scrollable: true,
      content: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.zoneSettingsIntro),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('age-field'),
              controller: _age,
              decoration: InputDecoration(labelText: l10n.ageLabel),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final age = int.tryParse(value ?? '');
                return age == null ||
                        age < ZoneSettings.minAge ||
                        age > ZoneSettings.maxAge
                    ? l10n.ageError(ZoneSettings.minAge, ZoneSettings.maxAge)
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('max-hr-field'),
              controller: _maxHr,
              decoration: InputDecoration(labelText: l10n.maxHrLabel),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final maxHr = int.tryParse(text);
                return maxHr == null ||
                        maxHr < ZoneSettings.minMaxHr ||
                        maxHr > ZoneSettings.maxMaxHr
                    ? l10n.maxHrError(
                        ZoneSettings.minMaxHr,
                        ZoneSettings.maxMaxHr,
                      )
                    : null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.maxHrNote(preview.maxHr),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final zone in HeartRateZone.values.skip(1).toList().reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: zoneColors.of(zone),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.zoneName(zone))),
                    Text(l10n.zoneRangeOf(zones, zone)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('save-zones'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
