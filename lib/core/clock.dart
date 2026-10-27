import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time in UTC. Uses `package:clock`, so widget tests run on
/// fake time.
final clockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => clock.now().toUtc(),
);
