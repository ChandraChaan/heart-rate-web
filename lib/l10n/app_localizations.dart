import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Web'**
  String get appTitle;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// No description provided for @zoneSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate zones'**
  String get zoneSettingsTooltip;

  /// No description provided for @sourceCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Source code on GitHub'**
  String get sourceCodeTooltip;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate, live in the browser'**
  String get connectTitle;

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect a Bluetooth heart-rate strap or armband: Polar, Garmin, Wahoo, Coospo and most others that use the standard Heart Rate service. Nothing to install.'**
  String get connectBody;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect a strap'**
  String get connectButton;

  /// No description provided for @demoButton.
  ///
  /// In en, this message translates to:
  /// **'Try demo mode'**
  String get demoButton;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'No strap? Demo mode streams a simulated chest strap through the same code.'**
  String get demoHint;

  /// No description provided for @connectTip.
  ///
  /// In en, this message translates to:
  /// **'Wet the strap\'s electrodes and put it on first, so it wakes up and shows in the list.'**
  String get connectTip;

  /// No description provided for @unsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'This browser can\'t use Bluetooth'**
  String get unsupportedTitle;

  /// No description provided for @unsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Web Bluetooth works in Chrome, Edge and Opera on Windows, macOS, ChromeOS and Android. Safari, every browser on iPhone and iPad, and Firefox don\'t support it. Demo mode works everywhere.'**
  String get unsupportedBody;

  /// No description provided for @connectingStrap.
  ///
  /// In en, this message translates to:
  /// **'Pick your sensor in the browser\'s list…'**
  String get connectingStrap;

  /// No description provided for @connectingDemo.
  ///
  /// In en, this message translates to:
  /// **'Starting the demo strap…'**
  String get connectingDemo;

  /// No description provided for @failureUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser doesn\'t support Web Bluetooth. Try Chrome or Edge on a computer or an Android phone.'**
  String get failureUnsupported;

  /// No description provided for @failureAdapterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off, or this device has no Bluetooth adapter. Turn it on and try again.'**
  String get failureAdapterUnavailable;

  /// No description provided for @failureCancelled.
  ///
  /// In en, this message translates to:
  /// **'No sensor was picked. Put the strap on so it wakes up, then try again.'**
  String get failureCancelled;

  /// No description provided for @failurePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth access was blocked. Check this site\'s permissions next to the address bar, and your system\'s Bluetooth privacy settings.'**
  String get failurePermissionDenied;

  /// No description provided for @failureNoHeartRateService.
  ///
  /// In en, this message translates to:
  /// **'That device doesn\'t offer the standard Heart Rate service.'**
  String get failureNoHeartRateService;

  /// No description provided for @failureConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Make sure the sensor is awake and not connected to another app, then try again.'**
  String get failureConnectionFailed;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Readings never leave your browser. Not a medical device.'**
  String get privacyNote;

  /// No description provided for @simulatedBadge.
  ///
  /// In en, this message translates to:
  /// **'SIMULATED'**
  String get simulatedBadge;

  /// No description provided for @simulatedBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: these readings come from a simulated strap, not a person.'**
  String get simulatedBanner;

  /// No description provided for @bpmUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpmUnit;

  /// No description provided for @waitingForData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first reading…'**
  String get waitingForData;

  /// No description provided for @contactWarning.
  ///
  /// In en, this message translates to:
  /// **'No skin contact. Wet the electrodes and tighten the strap.'**
  String get contactWarning;

  /// No description provided for @batteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String batteryLabel(int percent);

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get statusReconnecting;

  /// No description provided for @statusLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get statusLost;

  /// No description provided for @reconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnectButton;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @locationOther.
  ///
  /// In en, this message translates to:
  /// **'Other location'**
  String get locationOther;

  /// No description provided for @locationChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get locationChest;

  /// No description provided for @locationWrist.
  ///
  /// In en, this message translates to:
  /// **'Wrist'**
  String get locationWrist;

  /// No description provided for @locationFinger.
  ///
  /// In en, this message translates to:
  /// **'Finger'**
  String get locationFinger;

  /// No description provided for @locationHand.
  ///
  /// In en, this message translates to:
  /// **'Hand'**
  String get locationHand;

  /// No description provided for @locationEarLobe.
  ///
  /// In en, this message translates to:
  /// **'Ear lobe'**
  String get locationEarLobe;

  /// No description provided for @locationFoot.
  ///
  /// In en, this message translates to:
  /// **'Foot'**
  String get locationFoot;

  /// No description provided for @locationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get locationUnknown;

  /// No description provided for @zoneRest.
  ///
  /// In en, this message translates to:
  /// **'Below zone 1'**
  String get zoneRest;

  /// No description provided for @zone1.
  ///
  /// In en, this message translates to:
  /// **'Zone 1 · Very light'**
  String get zone1;

  /// No description provided for @zone2.
  ///
  /// In en, this message translates to:
  /// **'Zone 2 · Light'**
  String get zone2;

  /// No description provided for @zone3.
  ///
  /// In en, this message translates to:
  /// **'Zone 3 · Moderate'**
  String get zone3;

  /// No description provided for @zone4.
  ///
  /// In en, this message translates to:
  /// **'Zone 4 · Hard'**
  String get zone4;

  /// No description provided for @zone5.
  ///
  /// In en, this message translates to:
  /// **'Zone 5 · Maximum'**
  String get zone5;

  /// No description provided for @zoneShortRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get zoneShortRest;

  /// No description provided for @zoneShort.
  ///
  /// In en, this message translates to:
  /// **'Z{number}'**
  String zoneShort(int number);

  /// No description provided for @zoneRange.
  ///
  /// In en, this message translates to:
  /// **'{low}–{high} bpm'**
  String zoneRange(int low, int high);

  /// No description provided for @zoneRangeOpen.
  ///
  /// In en, this message translates to:
  /// **'{low}+ bpm'**
  String zoneRangeOpen(int low);

  /// No description provided for @zoneRangeBelow.
  ///
  /// In en, this message translates to:
  /// **'under {high} bpm'**
  String zoneRangeBelow(int high);

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 3 minutes'**
  String get chartTitle;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate chart of the last 3 minutes. Latest reading {bpm} bpm.'**
  String chartSemantics(int bpm);

  /// No description provided for @hrvTitle.
  ///
  /// In en, this message translates to:
  /// **'HRV (RMSSD)'**
  String get hrvTitle;

  /// No description provided for @hrvValue.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String hrvValue(int ms);

  /// No description provided for @hrvCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting beats…'**
  String get hrvCollecting;

  /// No description provided for @hrvNotSent.
  ///
  /// In en, this message translates to:
  /// **'This sensor doesn\'t send RR-intervals.'**
  String get hrvNotSent;

  /// No description provided for @hrvHelp.
  ///
  /// In en, this message translates to:
  /// **'Over the last minute. Most meaningful at rest.'**
  String get hrvHelp;

  /// No description provided for @energyTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energyTitle;

  /// No description provided for @energyValue.
  ///
  /// In en, this message translates to:
  /// **'{kj} kJ'**
  String energyValue(int kj);

  /// No description provided for @timeInZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Time in zones'**
  String get timeInZonesTitle;

  /// No description provided for @timeInZonesSinceConnect.
  ///
  /// In en, this message translates to:
  /// **'Since connecting'**
  String get timeInZonesSinceConnect;

  /// No description provided for @timeInZonesRecording.
  ///
  /// In en, this message translates to:
  /// **'This recording'**
  String get timeInZonesRecording;

  /// No description provided for @maxHrNote.
  ///
  /// In en, this message translates to:
  /// **'Max HR {maxHr} bpm'**
  String maxHrNote(int maxHr);

  /// No description provided for @recordButton.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get recordButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get stopButton;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording {elapsed}'**
  String recordingLabel(String elapsed);

  /// No description provided for @recordingHint.
  ///
  /// In en, this message translates to:
  /// **'Recordings are saved in this browser. Export them from the Sessions tab.'**
  String get recordingHint;

  /// No description provided for @nothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved: no valid readings were recorded.'**
  String get nothingRecorded;

  /// No description provided for @storageFull.
  ///
  /// In en, this message translates to:
  /// **'Browser storage is full. Export and delete old sessions, then try again.'**
  String get storageFull;

  /// No description provided for @sessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get sessionSaved;

  /// No description provided for @viewSession.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewSession;

  /// No description provided for @demoControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo controls'**
  String get demoControlsTitle;

  /// No description provided for @demoTakeOff.
  ///
  /// In en, this message translates to:
  /// **'Take strap off'**
  String get demoTakeOff;

  /// No description provided for @demoPutOn.
  ///
  /// In en, this message translates to:
  /// **'Put strap on'**
  String get demoPutOn;

  /// No description provided for @demoDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop connection'**
  String get demoDrop;

  /// No description provided for @zoneSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate zones'**
  String get zoneSettingsTitle;

  /// No description provided for @zoneSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Zones are shares of your maximum heart rate. Without a measured value, 220 − age is used, which can be 10 bpm or more off.'**
  String get zoneSettingsIntro;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageError.
  ///
  /// In en, this message translates to:
  /// **'Enter an age from {min} to {max}'**
  String ageError(int min, int max);

  /// No description provided for @maxHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured max heart rate (optional)'**
  String get maxHrLabel;

  /// No description provided for @maxHrError.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}–{max} bpm, or leave it empty'**
  String maxHrError(int min, int max);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get sessionsEmptyTitle;

  /// No description provided for @sessionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start recording on the Live tab. Sessions are kept in this browser only.'**
  String get sessionsEmptyBody;

  /// No description provided for @sessionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the saved sessions.'**
  String get sessionsLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{duration} · avg {average} · max {max} bpm'**
  String sessionSubtitle(String duration, int average, int max);

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This session no longer exists.'**
  String get sessionNotFound;

  /// No description provided for @summaryDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get summaryDuration;

  /// No description provided for @summaryAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get summaryAverage;

  /// No description provided for @summaryMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get summaryMax;

  /// No description provided for @summaryMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get summaryMin;

  /// No description provided for @summaryHrv.
  ///
  /// In en, this message translates to:
  /// **'HRV (RMSSD)'**
  String get summaryHrv;

  /// No description provided for @summaryEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get summaryEnergy;

  /// No description provided for @summarySensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get summarySensor;

  /// No description provided for @bpmValue.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String bpmValue(int bpm);

  /// No description provided for @noValue.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get noValue;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the file.'**
  String get exportFailed;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s stored only in this browser, so it can\'t be recovered. Export it first to keep a copy.'**
  String get deleteConfirmBody;

  /// No description provided for @sessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Session deleted'**
  String get sessionDeleted;

  /// No description provided for @wholeSessionChart.
  ///
  /// In en, this message translates to:
  /// **'Heart rate over the whole session'**
  String get wholeSessionChart;

  /// No description provided for @chartSessionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate chart of the session, average {average} bpm, max {max} bpm.'**
  String chartSessionSemantics(int average, int max);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
