import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Sidebar heading in the admin console
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// Admin sidebar destination
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// Admin sidebar destination
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// Tagline displayed on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Your people, your feed, your rules.'**
  String get splashTagline;

  /// Footer text displayed on the splash screen
  ///
  /// In en, this message translates to:
  /// **'SAFE & INCLUSIVE COMMUNITY'**
  String get splashCommunityText;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Short video,\nreal community.'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Post up to 60 seconds. No algorithm chasing outrage — you pick the communities that shape your feed.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Seven communities,\none loop.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Join the spaces you belong to. Each one has its own feed, and you can leave whenever you want.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Report, block, mute —\nalways one tap away.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Safety tools sit on every post and every message. Moderators review reports within 24 hours and tell you what happened.'**
  String get onboardingDesc3;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up where your loop left off.'**
  String get authWelcomeSub;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authCreateSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing you sign up with is shown publicly.'**
  String get authCreateSub;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ash@queerloop.app'**
  String get authEmailPlaceholder;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authStaySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get authStaySignedIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authSignInNow.
  ///
  /// In en, this message translates to:
  /// **'Sign In now.'**
  String get authSignInNow;

  /// No description provided for @authSignUpEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign up with email'**
  String get authSignUpEmail;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get authApple;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get authNewHere;

  /// No description provided for @authCreateAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAnAccount;

  /// No description provided for @authJustLooking.
  ///
  /// In en, this message translates to:
  /// **'Just looking? '**
  String get authJustLooking;

  /// No description provided for @authBrowseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as guest'**
  String get authBrowseAsGuest;

  /// No description provided for @authEnterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEnterEmailError;

  /// No description provided for @authEnterValidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEnterValidEmailError;

  /// No description provided for @authEnterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authEnterPasswordError;

  /// No description provided for @authPasswordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordLengthError;

  /// No description provided for @authEnterNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authEnterNameError;

  /// No description provided for @authEnterUsernameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get authEnterUsernameError;

  /// No description provided for @authUsernameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get authUsernameLengthError;

  /// No description provided for @authAccountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created!'**
  String get authAccountCreatedTitle;

  /// No description provided for @authAccountCreatedSub.
  ///
  /// In en, this message translates to:
  /// **'Welcome to QueerLoop+. Let\'s customize your profile settings so you feel right at home.'**
  String get authAccountCreatedSub;

  /// No description provided for @authContinueToProfileBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue to Profile Setup'**
  String get authContinueToProfileBtn;

  /// No description provided for @authAcceptTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms & Conditions and Privacy Policy to continue.'**
  String get authAcceptTermsError;

  /// No description provided for @authAgreeTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By joining you agree to the '**
  String get authAgreeTermsPrefix;

  /// No description provided for @authTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get authTermsConditions;

  /// No description provided for @authAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get authAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authPeriod.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get authPeriod;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccount;

  /// No description provided for @authCodeExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get authCodeExpiredTitle;

  /// No description provided for @authCodeExpiredSub.
  ///
  /// In en, this message translates to:
  /// **'Security codes expire after 10 minutes to protect your account.'**
  String get authCodeExpiredSub;

  /// No description provided for @authCodeExpiredStatus.
  ///
  /// In en, this message translates to:
  /// **'This code has expired.'**
  String get authCodeExpiredStatus;

  /// No description provided for @authSendNewCodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Send new code'**
  String get authSendNewCodeBtn;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authCreateNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get authCreateNewPasswordTitle;

  /// No description provided for @authCreateNewPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 6 characters.'**
  String get authCreateNewPasswordSub;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordHint;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authSaveNewPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get authSaveNewPasswordBtn;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Enter the email associated with your account and we\'ll send a code to reset your password.'**
  String get authResetPasswordSub;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authPasswordResetSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated!'**
  String get authPasswordResetSuccessTitle;

  /// No description provided for @authPasswordResetSuccessSub.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset. You can now log in with your new password.'**
  String get authPasswordResetSuccessSub;

  /// No description provided for @authBackToLoginBtn.
  ///
  /// In en, this message translates to:
  /// **'Back to Log in'**
  String get authBackToLoginBtn;

  /// No description provided for @authEnterYourCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get authEnterYourCodeTitle;

  /// No description provided for @authEnterYourCodeSub.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email. Enter it below to continue.'**
  String get authEnterYourCodeSub;

  /// No description provided for @authResendCodePrefix.
  ///
  /// In en, this message translates to:
  /// **'Resend code in '**
  String get authResendCodePrefix;

  /// No description provided for @authEnterCodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authEnterCodeBtn;

  /// No description provided for @profileSetupStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get profileSetupStep1Title;

  /// No description provided for @profileSetupStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'Your display name can be anything. Your username is how people find and tag you.'**
  String get profileSetupStep1Sub;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @profileNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ash Mercado'**
  String get profileNamePlaceholder;

  /// No description provided for @profileUsernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ashinorbit'**
  String get profileUsernamePlaceholder;

  /// No description provided for @profileBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Film nerd, softball catcher, chronically making playlists.'**
  String get profileBioPlaceholder;

  /// No description provided for @profileUsernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get profileUsernameAvailable;

  /// No description provided for @profileStepCounter.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String profileStepCounter(int current, int total);

  /// No description provided for @profileContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinueBtn;

  /// No description provided for @profileBackBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profileBackBtn;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY NAME'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ash Mercado'**
  String get profileDisplayNameHint;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get profileUsernameLabel;

  /// No description provided for @profileUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'ashinorbit'**
  String get profileUsernameHint;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'BIO'**
  String get profileBioLabel;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Film nerd, softball catcher, chronically making playlists.'**
  String get profileBioHint;

  /// No description provided for @profileStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Add a photo.'**
  String get profileStep2Title;

  /// No description provided for @profileStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'A face, an edit, an artwork. Clear photos help connections grow — you can skip for now if you prefer.'**
  String get profileStep2Sub;

  /// No description provided for @profileUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get profileUploadPhoto;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileTakePhoto;

  /// No description provided for @profileSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get profileSkipForNow;

  /// No description provided for @profileUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get profileUpload;

  /// No description provided for @profileStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Select your pronouns.'**
  String get profileStep3Title;

  /// No description provided for @profileStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply. They will sit right under your handle everywhere you post.'**
  String get profileStep3Sub;

  /// No description provided for @profileChooseCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose custom pronouns...'**
  String get profileChooseCustom;

  /// No description provided for @profileWriteOwn.
  ///
  /// In en, this message translates to:
  /// **'WRITE YOUR OWN'**
  String get profileWriteOwn;

  /// No description provided for @profileTypePronounsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. xe/xem/xyrs'**
  String get profileTypePronounsPlaceholder;

  /// No description provided for @profileAddBtn.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get profileAddBtn;

  /// No description provided for @profileAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get profileAdd;

  /// No description provided for @profileCustomPronounHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. xe/xem/xyrs'**
  String get profileCustomPronounHint;

  /// No description provided for @profileCustomLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 3 custom pronoun sets.'**
  String get profileCustomLimitWarning;

  /// No description provided for @profileStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Choose your communities.'**
  String get profileStep4Title;

  /// No description provided for @profileStep4Sub.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 2. You will see posts and videos from these spaces on your Home loop.'**
  String get profileStep4Sub;

  /// No description provided for @profileAllCommunitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Communities'**
  String get profileAllCommunitiesTitle;

  /// No description provided for @profileSearchCommunities.
  ///
  /// In en, this message translates to:
  /// **'Search communities...'**
  String get profileSearchCommunities;

  /// No description provided for @profileViewAllCommunities.
  ///
  /// In en, this message translates to:
  /// **'View all communities'**
  String get profileViewAllCommunities;

  /// No description provided for @profileSelectCommunityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one community to continue.'**
  String get profileSelectCommunityRequired;

  /// No description provided for @profileStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Your privacy, your calls.'**
  String get profileStep5Title;

  /// No description provided for @profileStep5Sub.
  ///
  /// In en, this message translates to:
  /// **'Defaults stay tight. Change any setting now, or tweak them later in your profile.'**
  String get profileStep5Sub;

  /// No description provided for @profileHideProfileFromSearch.
  ///
  /// In en, this message translates to:
  /// **'Hide profile from search'**
  String get profileHideProfileFromSearch;

  /// No description provided for @profileHideProfileFromSearchSub.
  ///
  /// In en, this message translates to:
  /// **'People can only find you by exact handle or direct link'**
  String get profileHideProfileFromSearchSub;

  /// No description provided for @profileShowInDiscover.
  ///
  /// In en, this message translates to:
  /// **'Show in Discover feed'**
  String get profileShowInDiscover;

  /// No description provided for @profileShowInDiscoverSub.
  ///
  /// In en, this message translates to:
  /// **'Allow your public posts to be suggested to community members'**
  String get profileShowInDiscoverSub;

  /// No description provided for @profileAllowMessagesFrom.
  ///
  /// In en, this message translates to:
  /// **'Allow messages from'**
  String get profileAllowMessagesFrom;

  /// No description provided for @profileHideMyLikes.
  ///
  /// In en, this message translates to:
  /// **'Hide my likes'**
  String get profileHideMyLikes;

  /// No description provided for @profileHideMyLikesSub.
  ///
  /// In en, this message translates to:
  /// **'Posts you like will not appear on your public profile'**
  String get profileHideMyLikesSub;

  /// No description provided for @profileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get profileVisibility;

  /// No description provided for @profileEnterQueerLoop.
  ///
  /// In en, this message translates to:
  /// **'Enter QueerLoop+'**
  String get profileEnterQueerLoop;

  /// No description provided for @profileOptionEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get profileOptionEveryone;

  /// No description provided for @profileOptionPeopleYouFollow.
  ///
  /// In en, this message translates to:
  /// **'People you follow'**
  String get profileOptionPeopleYouFollow;

  /// No description provided for @profileOptionMutualFollows.
  ///
  /// In en, this message translates to:
  /// **'Mutual follows'**
  String get profileOptionMutualFollows;

  /// No description provided for @profileOptionNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get profileOptionNobody;

  /// No description provided for @profileAllowMessageFromTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow messages from'**
  String get profileAllowMessageFromTitle;

  /// No description provided for @profileAllowMessageFromSub.
  ///
  /// In en, this message translates to:
  /// **'Choose who can send you direct messages.'**
  String get profileAllowMessageFromSub;

  /// No description provided for @profileVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get profileVisibilityTitle;

  /// No description provided for @profileVisibilitySub.
  ///
  /// In en, this message translates to:
  /// **'Choose who can view your profile.'**
  String get profileVisibilitySub;

  /// No description provided for @profilePrivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Private Account'**
  String get profilePrivateAccount;

  /// No description provided for @profilePrivateAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Only approved followers can see your posts and activity'**
  String get profilePrivateAccountSub;

  /// No description provided for @profileRecommendedDefault.
  ///
  /// In en, this message translates to:
  /// **'Recommended default'**
  String get profileRecommendedDefault;

  /// No description provided for @homeTabFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get homeTabFollowing;

  /// No description provided for @homeTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get homeTabForYou;

  /// No description provided for @homeTabCommunities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get homeTabCommunities;

  /// No description provided for @homeSubReels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get homeSubReels;

  /// No description provided for @homeSubPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get homeSubPosts;

  /// No description provided for @homeAllCommunitiesTag.
  ///
  /// In en, this message translates to:
  /// **'All Communities'**
  String get homeAllCommunitiesTag;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeNavDiscover;

  /// No description provided for @homeNavMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get homeNavMessages;

  /// No description provided for @homeNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Explore communities to start populating your feed.'**
  String get homeEmptySub;

  /// No description provided for @homeOpenExploreBtn.
  ///
  /// In en, this message translates to:
  /// **'Explore Communities'**
  String get homeOpenExploreBtn;

  /// No description provided for @homeSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get homeSafety;

  /// No description provided for @homeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeShare;

  /// No description provided for @homeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get homeSave;

  /// No description provided for @homeFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get homeFollowing;

  /// No description provided for @homeFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get homeFollow;

  /// No description provided for @filterCommunitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by Community'**
  String get filterCommunitiesTitle;

  /// No description provided for @filterCommunitiesSub.
  ///
  /// In en, this message translates to:
  /// **'Choose a community to customize your feed view.'**
  String get filterCommunitiesSub;

  /// No description provided for @filterApplyBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get filterApplyBtn;

  /// No description provided for @commentsHeader.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS'**
  String get commentsHeader;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS'**
  String get commentsTitle;

  /// No description provided for @commentsAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentsAddPlaceholder;

  /// No description provided for @commentReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentReply;

  /// No description provided for @commentReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commentReport;

  /// No description provided for @commentAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get commentAuthor;

  /// No description provided for @commentHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Comment hidden'**
  String get commentHiddenTitle;

  /// No description provided for @commentHiddenSub.
  ///
  /// In en, this message translates to:
  /// **'This comment was flagged for moderation.'**
  String get commentHiddenSub;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentPlaceholder;

  /// No description provided for @shareSendToHeader.
  ///
  /// In en, this message translates to:
  /// **'SEND TO'**
  String get shareSendToHeader;

  /// No description provided for @shareMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get shareMore;

  /// No description provided for @shareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareCopyLink;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get shareReport;

  /// No description provided for @shareNoticeText.
  ///
  /// In en, this message translates to:
  /// **'Sharing outside the app strips the poster\'s location data.'**
  String get shareNoticeText;

  /// No description provided for @shareCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shareCancelBtn;

  /// No description provided for @sharePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this post'**
  String get sharePostTitle;

  /// No description provided for @sendToTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get sendToTitle;

  /// No description provided for @sendToSelected.
  ///
  /// In en, this message translates to:
  /// **'1 selected'**
  String get sendToSelected;

  /// No description provided for @sendToSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search connection...'**
  String get sendToSearchHint;

  /// No description provided for @sendToTopConnections.
  ///
  /// In en, this message translates to:
  /// **'TOP CONNECTIONS'**
  String get sendToTopConnections;

  /// No description provided for @sendToWriteMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get sendToWriteMessageHint;

  /// No description provided for @sendToBtn.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendToBtn;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyTitle;

  /// No description provided for @safetySub.
  ///
  /// In en, this message translates to:
  /// **'Choose what happens with @rowankeeps and this post. We never tell them you used these tools.'**
  String get safetySub;

  /// No description provided for @safetyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get safetyReportTitle;

  /// No description provided for @safetyReportSub.
  ///
  /// In en, this message translates to:
  /// **'A moderator reviews it within 24 hours'**
  String get safetyReportSub;

  /// No description provided for @safetyBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block @rowankeeps'**
  String get safetyBlockTitle;

  /// No description provided for @safetyBlockSub.
  ///
  /// In en, this message translates to:
  /// **'They lose all contact with you'**
  String get safetyBlockSub;

  /// No description provided for @guestSignUpBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get guestSignUpBtn;

  /// No description provided for @guestJoinToLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join to like, comment and post'**
  String get guestJoinToLikeTitle;

  /// No description provided for @guestJoinToLikeSub.
  ///
  /// In en, this message translates to:
  /// **'Guests see a limited public feed. Reporting still works without an account.'**
  String get guestJoinToLikeSub;

  /// No description provided for @guestCreateFreeAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create free account'**
  String get guestCreateFreeAccountBtn;

  /// No description provided for @guestSignUpBrowseCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to browse community'**
  String get guestSignUpBrowseCommunityTitle;

  /// No description provided for @guestSignUpBrowseCommunitySub.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to see communities, react and join the communities. Browsing stays free forever.'**
  String get guestSignUpBrowseCommunitySub;

  /// No description provided for @guestSignUpSendMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to send messages'**
  String get guestSignUpSendMessagesTitle;

  /// No description provided for @guestSignUpSendMessagesSub.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to DM people, react and join the conversation. Browsing stays free forever.'**
  String get guestSignUpSendMessagesSub;

  /// No description provided for @guestNotReadyKeepBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Not ready? Keep browsing as guest'**
  String get guestNotReadyKeepBrowsing;

  /// No description provided for @guestNotReadyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Not ready?'**
  String get guestNotReadyPrefix;

  /// No description provided for @guestKeepBrowsingText.
  ///
  /// In en, this message translates to:
  /// **'Keep browsing as guest'**
  String get guestKeepBrowsingText;

  /// No description provided for @guestProfileHeader.
  ///
  /// In en, this message translates to:
  /// **'GUEST'**
  String get guestProfileHeader;

  /// No description provided for @guestProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as Guest'**
  String get guestProfileTitle;

  /// No description provided for @guestProfileSub.
  ///
  /// In en, this message translates to:
  /// **'No name, photo or bio yet — sign up to build a profile people can find and follow.'**
  String get guestProfileSub;

  /// No description provided for @guestDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get guestDiscoverTitle;

  /// No description provided for @guestDiscoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search people, posts, tags'**
  String get guestDiscoverSearchHint;

  /// No description provided for @guestTrendingNow.
  ///
  /// In en, this message translates to:
  /// **'TRENDING NOW'**
  String get guestTrendingNow;

  /// No description provided for @guestWorldwide.
  ///
  /// In en, this message translates to:
  /// **'Worldwide'**
  String get guestWorldwide;

  /// No description provided for @guestBrowseCommunities.
  ///
  /// In en, this message translates to:
  /// **'BROWSE COMMUNITIES'**
  String get guestBrowseCommunities;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
