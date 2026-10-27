// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Heart Rate Web';

  @override
  String get navLive => 'Live';

  @override
  String get navSessions => 'Sessions';

  @override
  String get zoneSettingsTooltip => 'Heart-rate zones';

  @override
  String get sourceCodeTooltip => 'Source code on GitHub';

  @override
  String get connectTitle => 'Your heart rate, live in the browser';

  @override
  String get connectBody =>
      'Connect a Bluetooth heart-rate strap or armband: Polar, Garmin, Wahoo, Coospo and most others that use the standard Heart Rate service. Nothing to install.';

  @override
  String get connectButton => 'Connect a strap';

  @override
  String get demoButton => 'Try demo mode';

  @override
  String get demoHint =>
      'No strap? Demo mode streams a simulated chest strap through the same code.';

  @override
  String get connectTip =>
      'Wet the strap\'s electrodes and put it on first, so it wakes up and shows in the list.';

  @override
  String get unsupportedTitle => 'This browser can\'t use Bluetooth';

  @override
  String get unsupportedBody =>
      'Web Bluetooth works in Chrome, Edge and Opera on Windows, macOS, ChromeOS and Android. Safari, every browser on iPhone and iPad, and Firefox don\'t support it. Demo mode works everywhere.';

  @override
  String get connectingStrap => 'Pick your sensor in the browser\'s list…';

  @override
  String get connectingDemo => 'Starting the demo strap…';

  @override
  String get failureUnsupported =>
      'This browser doesn\'t support Web Bluetooth. Try Chrome or Edge on a computer or an Android phone.';

  @override
  String get failureAdapterUnavailable =>
      'Bluetooth is off, or this device has no Bluetooth adapter. Turn it on and try again.';

  @override
  String get failureCancelled =>
      'No sensor was picked. Put the strap on so it wakes up, then try again.';

  @override
  String get failurePermissionDenied =>
      'Bluetooth access was blocked. Check this site\'s permissions next to the address bar, and your system\'s Bluetooth privacy settings.';

  @override
  String get failureNoHeartRateService =>
      'That device doesn\'t offer the standard Heart Rate service.';

  @override
  String get failureConnectionFailed =>
      'Couldn\'t connect. Make sure the sensor is awake and not connected to another app, then try again.';

  @override
  String get privacyNote =>
      'Readings never leave your browser. Not a medical device.';

  @override
  String get simulatedBadge => 'SIMULATED';

  @override
  String get simulatedBanner =>
      'Demo mode: these readings come from a simulated strap, not a person.';

  @override
  String get bpmUnit => 'bpm';

  @override
  String get waitingForData => 'Waiting for the first reading…';

  @override
  String get contactWarning =>
      'No skin contact. Wet the electrodes and tighten the strap.';

  @override
  String batteryLabel(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusReconnecting => 'Reconnecting…';

  @override
  String get statusLost => 'Connection lost';

  @override
  String get reconnectButton => 'Reconnect';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get locationOther => 'Other location';

  @override
  String get locationChest => 'Chest';

  @override
  String get locationWrist => 'Wrist';

  @override
  String get locationFinger => 'Finger';

  @override
  String get locationHand => 'Hand';

  @override
  String get locationEarLobe => 'Ear lobe';

  @override
  String get locationFoot => 'Foot';

  @override
  String get locationUnknown => 'Unknown location';

  @override
  String get zoneRest => 'Below zone 1';

  @override
  String get zone1 => 'Zone 1 · Very light';

  @override
  String get zone2 => 'Zone 2 · Light';

  @override
  String get zone3 => 'Zone 3 · Moderate';

  @override
  String get zone4 => 'Zone 4 · Hard';

  @override
  String get zone5 => 'Zone 5 · Maximum';

  @override
  String get zoneShortRest => 'Rest';

  @override
  String zoneShort(int number) {
    return 'Z$number';
  }

  @override
  String zoneRange(int low, int high) {
    return '$low–$high bpm';
  }

  @override
  String zoneRangeOpen(int low) {
    return '$low+ bpm';
  }

  @override
  String zoneRangeBelow(int high) {
    return 'under $high bpm';
  }

  @override
  String get chartTitle => 'Last 3 minutes';

  @override
  String chartSemantics(int bpm) {
    return 'Heart-rate chart of the last 3 minutes. Latest reading $bpm bpm.';
  }

  @override
  String get hrvTitle => 'HRV (RMSSD)';

  @override
  String hrvValue(int ms) {
    return '$ms ms';
  }

  @override
  String get hrvCollecting => 'Collecting beats…';

  @override
  String get hrvNotSent => 'This sensor doesn\'t send RR-intervals.';

  @override
  String get hrvHelp => 'Over the last minute. Most meaningful at rest.';

  @override
  String get energyTitle => 'Energy';

  @override
  String energyValue(int kj) {
    return '$kj kJ';
  }

  @override
  String get timeInZonesTitle => 'Time in zones';

  @override
  String get timeInZonesSinceConnect => 'Since connecting';

  @override
  String get timeInZonesRecording => 'This recording';

  @override
  String maxHrNote(int maxHr) {
    return 'Max HR $maxHr bpm';
  }

  @override
  String get recordButton => 'Start recording';

  @override
  String get stopButton => 'Stop and save';

  @override
  String recordingLabel(String elapsed) {
    return 'Recording $elapsed';
  }

  @override
  String get recordingHint =>
      'Recordings are saved in this browser. Export them from the Sessions tab.';

  @override
  String get nothingRecorded =>
      'Nothing saved: no valid readings were recorded.';

  @override
  String get storageFull =>
      'Browser storage is full. Export and delete old sessions, then try again.';

  @override
  String get sessionSaved => 'Session saved';

  @override
  String get viewSession => 'View';

  @override
  String get demoControlsTitle => 'Demo controls';

  @override
  String get demoTakeOff => 'Take strap off';

  @override
  String get demoPutOn => 'Put strap on';

  @override
  String get demoDrop => 'Drop connection';

  @override
  String get zoneSettingsTitle => 'Heart-rate zones';

  @override
  String get zoneSettingsIntro =>
      'Zones are shares of your maximum heart rate. Without a measured value, 220 − age is used, which can be 10 bpm or more off.';

  @override
  String get ageLabel => 'Age';

  @override
  String ageError(int min, int max) {
    return 'Enter an age from $min to $max';
  }

  @override
  String get maxHrLabel => 'Measured max heart rate (optional)';

  @override
  String maxHrError(int min, int max) {
    return 'Enter $min–$max bpm, or leave it empty';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get sessionsEmptyTitle => 'No sessions yet';

  @override
  String get sessionsEmptyBody =>
      'Start recording on the Live tab. Sessions are kept in this browser only.';

  @override
  String get sessionsLoadError => 'Couldn\'t read the saved sessions.';

  @override
  String get retry => 'Retry';

  @override
  String sessionSubtitle(String duration, int average, int max) {
    return '$duration · avg $average · max $max bpm';
  }

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionNotFound => 'This session no longer exists.';

  @override
  String get summaryDuration => 'Duration';

  @override
  String get summaryAverage => 'Average';

  @override
  String get summaryMax => 'Max';

  @override
  String get summaryMin => 'Min';

  @override
  String get summaryHrv => 'HRV (RMSSD)';

  @override
  String get summaryEnergy => 'Energy';

  @override
  String get summarySensor => 'Sensor';

  @override
  String bpmValue(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get noValue => '–';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportTcx => 'Export TCX';

  @override
  String get exportTcxHint =>
      'For Strava, Garmin Connect and other training apps';

  @override
  String get tcxSportRunning => 'As a run';

  @override
  String get tcxSportBiking => 'As a ride';

  @override
  String get tcxSportOther => 'As another workout';

  @override
  String get exportFailed => 'Couldn\'t create the file.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete this session?';

  @override
  String get deleteConfirmBody =>
      'It\'s stored only in this browser, so it can\'t be recovered. Export it first to keep a copy.';

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get wholeSessionChart => 'Heart rate over the whole session';

  @override
  String chartSessionSemantics(int average, int max) {
    return 'Heart-rate chart of the session, average $average bpm, max $max bpm.';
  }
}
