import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ReclaimAppLocalizations
/// returned by `ReclaimAppLocalizations.of(context)`.
///
/// Applications need to include `ReclaimAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ReclaimAppLocalizations.localizationsDelegates,
///   supportedLocales: ReclaimAppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ReclaimAppLocalizations.supportedLocales
/// property.
abstract class ReclaimAppLocalizations {
  ReclaimAppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ReclaimAppLocalizations? of(BuildContext context) {
    return Localizations.of<ReclaimAppLocalizations>(context, ReclaimAppLocalizations);
  }

  static const LocalizationsDelegate<ReclaimAppLocalizations> delegate = _ReclaimAppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es')];

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default Language'**
  String get defaultLanguage;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @verificationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Verification cancelled'**
  String get verificationCancelled;

  /// No description provided for @verificationDismissedByUser.
  ///
  /// In en, this message translates to:
  /// **'Verification dismissed by user'**
  String get verificationDismissedByUser;

  /// No description provided for @providerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Provider not found'**
  String get providerNotFound;

  /// No description provided for @weCouldntDeliverProofs.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t deliver proofs to \"{appName}\".'**
  String weCouldntDeliverProofs({required String appName});

  /// No description provided for @verifyingFor.
  ///
  /// In en, this message translates to:
  /// **'Verifying for {appName}'**
  String verifyingFor({required String appName});

  /// No description provided for @platformNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Platform not supported'**
  String get platformNotSupported;

  /// No description provided for @inappSdkVersionIsOutdatedAndNotFunctionalAnymore.
  ///
  /// In en, this message translates to:
  /// **'InApp SDK version is outdated and not functional anymore'**
  String get inappSdkVersionIsOutdatedAndNotFunctionalAnymore;

  /// No description provided for @requirementForVerificationCouldNotBeMet.
  ///
  /// In en, this message translates to:
  /// **'Requirement for verification could not be met'**
  String get requirementForVerificationCouldNotBeMet;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @gettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get gettingReady;

  /// No description provided for @gettingReadyToVerify.
  ///
  /// In en, this message translates to:
  /// **'Getting ready to verify'**
  String get gettingReadyToVerify;

  /// No description provided for @almostThereJustFinalizingTheDetails.
  ///
  /// In en, this message translates to:
  /// **'Almost there, just finalizing the details'**
  String get almostThereJustFinalizingTheDetails;

  /// No description provided for @pleaseHoldOnForJustALittleLonger.
  ///
  /// In en, this message translates to:
  /// **'Please hold on for just a little longer'**
  String get pleaseHoldOnForJustALittleLonger;

  /// No description provided for @thisShouldntTakeMuchLonger.
  ///
  /// In en, this message translates to:
  /// **'This shouldn\'t take much longer'**
  String get thisShouldntTakeMuchLonger;

  /// No description provided for @verifyingDataFrom.
  ///
  /// In en, this message translates to:
  /// **'Verifying data from {domain}'**
  String verifyingDataFrom({required String domain});

  /// No description provided for @waitingForVerificationStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification to start…'**
  String get waitingForVerificationStart;

  /// No description provided for @thisMightTakeAFewSeconds.
  ///
  /// In en, this message translates to:
  /// **'This might take a few seconds'**
  String get thisMightTakeAFewSeconds;

  /// No description provided for @waitingForVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification'**
  String get waitingForVerification;

  /// No description provided for @sharingWith.
  ///
  /// In en, this message translates to:
  /// **'Sharing with {appName}'**
  String sharingWith({required String appName});

  /// No description provided for @youAlwaysControlWhoYouShareYourDataWith.
  ///
  /// In en, this message translates to:
  /// **'You always control who you share your data with'**
  String get youAlwaysControlWhoYouShareYourDataWith;

  /// No description provided for @youAreInCompleteControlOfYourData.
  ///
  /// In en, this message translates to:
  /// **'You are in complete control of your data'**
  String get youAreInCompleteControlOfYourData;

  /// No description provided for @lookingForInformationToVerify.
  ///
  /// In en, this message translates to:
  /// **'Looking for information to verify'**
  String get lookingForInformationToVerify;

  /// No description provided for @findOurTermsOfServicePrivacyPolicyAt.
  ///
  /// In en, this message translates to:
  /// **'Find our terms of service & privacy policy at _reclaimprotocol.org_'**
  String get findOurTermsOfServicePrivacyPolicyAt;

  /// No description provided for @byContinuingYouAgreeToThese.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to these _Terms of Service@1_ and _Privacy Policy@2_'**
  String get byContinuingYouAgreeToThese;

  /// No description provided for @infinite.
  ///
  /// In en, this message translates to:
  /// **'Infinite'**
  String get infinite;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'loading…'**
  String get loading;

  /// No description provided for @copiedToYourClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to your clipboard'**
  String get copiedToYourClipboard;

  /// No description provided for @proofsGeneratedByReclaimProtocolAreSecureAndPrivate.
  ///
  /// In en, this message translates to:
  /// **'Proofs generated by Reclaim Protocol are secure and private.'**
  String get proofsGeneratedByReclaimProtocolAreSecureAndPrivate;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @dontAllow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Allow'**
  String get dontAllow;

  /// No description provided for @copySessionId.
  ///
  /// In en, this message translates to:
  /// **'Copy Session ID'**
  String get copySessionId;

  /// No description provided for @refreshPage.
  ///
  /// In en, this message translates to:
  /// **'Refresh Page'**
  String get refreshPage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @troubleshootingMode.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting Mode'**
  String get troubleshootingMode;

  /// No description provided for @saveWebsiteData.
  ///
  /// In en, this message translates to:
  /// **'Save Website Data'**
  String get saveWebsiteData;

  /// No description provided for @requestingPermission.
  ///
  /// In en, this message translates to:
  /// **'Requesting permission'**
  String get requestingPermission;

  /// No description provided for @areYouSureYouSeeAllTheDataThatNeedsVerification.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you see all the data that needs verification?'**
  String get areYouSureYouSeeAllTheDataThatNeedsVerification;

  /// No description provided for @shareRequests.
  ///
  /// In en, this message translates to:
  /// **'Share requests'**
  String get shareRequests;

  /// No description provided for @tapShareToSendForManualReview.
  ///
  /// In en, this message translates to:
  /// **'Tap (share) to send for manual review'**
  String get tapShareToSendForManualReview;

  /// No description provided for @wantsToAccessYour.
  ///
  /// In en, this message translates to:
  /// **'{domain} wants to access your {resource}'**
  String wantsToAccessYour({required String domain, required String resource});

  /// No description provided for @contactApplicationSupportForMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact application support for more information.'**
  String get contactApplicationSupportForMoreInformation;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @createAndVerifyDataInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Create and verify data in seconds'**
  String get createAndVerifyDataInSeconds;

  /// No description provided for @orBrowseSomeOfOur.
  ///
  /// In en, this message translates to:
  /// **'Or browse some of our _sample providers_'**
  String get orBrowseSomeOfOur;

  /// No description provided for @returnTo.
  ///
  /// In en, this message translates to:
  /// **'Return to {appName}'**
  String returnTo({required String appName});

  /// No description provided for @youCanNowReturnTo.
  ///
  /// In en, this message translates to:
  /// **'You can now return to {appName}'**
  String youCanNowReturnTo({required String appName});

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @invalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid Link'**
  String get invalidLink;

  /// No description provided for @theRequestedProofLinkIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The requested proof link is invalid'**
  String get theRequestedProofLinkIsInvalid;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noProvidersFound.
  ///
  /// In en, this message translates to:
  /// **'No providers found'**
  String get noProvidersFound;

  /// No description provided for @pasteTheRequestedProofLinkHere.
  ///
  /// In en, this message translates to:
  /// **'Paste the requested proof link here'**
  String get pasteTheRequestedProofLinkHere;

  /// No description provided for @searchForAProvider.
  ///
  /// In en, this message translates to:
  /// **'Search for a provider'**
  String get searchForAProvider;

  /// No description provided for @searchByProvider.
  ///
  /// In en, this message translates to:
  /// **'Search by provider'**
  String get searchByProvider;

  /// No description provided for @youPreviouslyVerifiedThisData.
  ///
  /// In en, this message translates to:
  /// **'You previously verified this data'**
  String get youPreviouslyVerifiedThisData;

  /// No description provided for @verifyAgain.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get verifyAgain;

  /// No description provided for @shareData.
  ///
  /// In en, this message translates to:
  /// **'Share data'**
  String get shareData;

  /// No description provided for @isRequestingADataFrom.
  ///
  /// In en, this message translates to:
  /// **'{appName} is requesting a data from {user}'**
  String isRequestingADataFrom({required String appName, required String user});

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @proofSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Proof submission failed'**
  String get proofSubmissionFailed;

  /// No description provided for @anUnknownProblemOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unknown problem occurred'**
  String get anUnknownProblemOccurred;

  /// No description provided for @outdated.
  ///
  /// In en, this message translates to:
  /// **'Outdated'**
  String get outdated;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @verificationRequestInvalid.
  ///
  /// In en, this message translates to:
  /// **'The verification request is invalid. Please try starting verification again. If the problem persists, please contact {appName}.'**
  String verificationRequestInvalid({required String appName});

  /// No description provided for @unsupportedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unsupported device'**
  String get unsupportedDevice;

  /// No description provided for @thisDeviceIsNotSupportedForVerifications.
  ///
  /// In en, this message translates to:
  /// **'This device is not supported for verifications. Please try on a different device.'**
  String get thisDeviceIsNotSupportedForVerifications;

  /// No description provided for @thisVersionOfAppIsNotSupportedAnymore.
  ///
  /// In en, this message translates to:
  /// **'This version of app is not supported anymore. Please try again after updating.'**
  String get thisVersionOfAppIsNotSupportedAnymore;

  /// No description provided for @yourLoginCredentialsAndPrivateDataStaySecure.
  ///
  /// In en, this message translates to:
  /// **'Your login credentials and private data stay secure and are never visible to {appName}, Reclaim Protocol, or anyone else.'**
  String yourLoginCredentialsAndPrivateDataStaySecure({required Object appName});

  /// No description provided for @theApplicationHasEncounteredAnUnknownError.
  ///
  /// In en, this message translates to:
  /// **'The application has encountered an unknown error. Please try again later.'**
  String get theApplicationHasEncounteredAnUnknownError;

  /// No description provided for @tapOnTheLinkOnTheOtherAppBrowser.
  ///
  /// In en, this message translates to:
  /// **'Tap on the link, on the other app/browser you were using, to initiate verification'**
  String get tapOnTheLinkOnTheOtherAppBrowser;

  /// No description provided for @proofGenerationWasCancelledByTheUser.
  ///
  /// In en, this message translates to:
  /// **'Proof generation was cancelled by the user'**
  String get proofGenerationWasCancelledByTheUser;

  /// No description provided for @whatWasShared.
  ///
  /// In en, this message translates to:
  /// **'What was shared'**
  String get whatWasShared;

  /// No description provided for @whatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get whatWentWrong;

  /// No description provided for @dataSavedShared.
  ///
  /// In en, this message translates to:
  /// **'Data Saved & Shared'**
  String get dataSavedShared;

  /// No description provided for @dataShared.
  ///
  /// In en, this message translates to:
  /// **'Data Shared'**
  String get dataShared;

  /// No description provided for @wereReviewingYourSubmission.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your submission'**
  String get wereReviewingYourSubmission;

  /// No description provided for @unexpectedErrorOccurredDuringVerification.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during verification. {message}. If the problem persists, please contact {appName}.'**
  String unexpectedErrorOccurredDuringVerification({required String message, required String appName});

  /// No description provided for @invalidVerificationRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification request'**
  String get invalidVerificationRequest;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @yourDataHasBeenSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your data has been submitted successfully and is currently under manual review by our team. No further action is required from your side. We\'ll notify you once the review is complete.'**
  String get yourDataHasBeenSubmittedSuccessfully;

  /// No description provided for @why.
  ///
  /// In en, this message translates to:
  /// **'WHY?'**
  String get why;

  /// No description provided for @verificationSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'The verification session has expired. Please try starting verification again from {appName}.'**
  String verificationSessionExpired({required String appName});

  /// No description provided for @updateForInappSdkAvailableCritical.
  ///
  /// In en, this message translates to:
  /// **'⚠️🚨 An update for inapp SDK is available. The current version cannot be used anymore, please update the inapp SDK version used by this app to ensure support.'**
  String get updateForInappSdkAvailableCritical;

  /// No description provided for @updateForInappSdkAvailableWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ An update for inapp SDK is available. Please update the inapp SDK version used by this app to ensure support.'**
  String get updateForInappSdkAvailableWarning;

  /// No description provided for @forMoreInformationAboutThisError.
  ///
  /// In en, this message translates to:
  /// **'For more information about this error, please  _see potential failure reasons._'**
  String get forMoreInformationAboutThisError;

  /// No description provided for @verifyingStudentStatus.
  ///
  /// In en, this message translates to:
  /// **'Verifying student status for {providerName}.'**
  String verifyingStudentStatus({required String providerName});
}

class _ReclaimAppLocalizationsDelegate extends LocalizationsDelegate<ReclaimAppLocalizations> {
  const _ReclaimAppLocalizationsDelegate();

  @override
  Future<ReclaimAppLocalizations> load(Locale locale) {
    return SynchronousFuture<ReclaimAppLocalizations>(lookupReclaimAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_ReclaimAppLocalizationsDelegate old) => false;
}

ReclaimAppLocalizations lookupReclaimAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ReclaimAppLocalizationsEn();
    case 'es':
      return ReclaimAppLocalizationsEs();
  }

  throw FlutterError(
    'ReclaimAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
