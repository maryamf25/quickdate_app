import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'QuickDate'**
  String get appName;

  /// No description provided for @tab_match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get tab_match;

  /// No description provided for @tab_trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get tab_trending;

  /// No description provided for @tab_alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tab_alerts;

  /// No description provided for @tab_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tab_chats;

  /// No description provided for @tab_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tab_settings;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @my_account.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get my_account;

  /// No description provided for @my_account_sub.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile and settings'**
  String get my_account_sub;

  /// No description provided for @social_links.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get social_links;

  /// No description provided for @social_links_sub.
  ///
  /// In en, this message translates to:
  /// **'Connect your social media accounts'**
  String get social_links_sub;

  /// No description provided for @blocked_users.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blocked_users;

  /// No description provided for @blocked_users_sub.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked users'**
  String get blocked_users_sub;

  /// No description provided for @my_affiliates.
  ///
  /// In en, this message translates to:
  /// **'My Affiliates'**
  String get my_affiliates;

  /// No description provided for @my_affiliates_sub.
  ///
  /// In en, this message translates to:
  /// **'Earn rewards for referrals'**
  String get my_affiliates_sub;

  /// No description provided for @messenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get messenger;

  /// No description provided for @show_active.
  ///
  /// In en, this message translates to:
  /// **'Show when you\'re active'**
  String get show_active;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @show_profile_search.
  ///
  /// In en, this message translates to:
  /// **'Show my profile on search engines?'**
  String get show_profile_search;

  /// No description provided for @show_profile_random.
  ///
  /// In en, this message translates to:
  /// **'Show my profile to random users?'**
  String get show_profile_random;

  /// No description provided for @show_profile_match.
  ///
  /// In en, this message translates to:
  /// **'Show my profile in the match page?'**
  String get show_profile_match;

  /// No description provided for @confirm_friend.
  ///
  /// In en, this message translates to:
  /// **'Confirm friend requests before accepting?'**
  String get confirm_friend;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @password_sub.
  ///
  /// In en, this message translates to:
  /// **'Change your account password'**
  String get password_sub;

  /// No description provided for @two_factor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get two_factor;

  /// No description provided for @manage_sessions.
  ///
  /// In en, this message translates to:
  /// **'Manage Sessions'**
  String get manage_sessions;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @withdrawals_sub.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your earnings via PayPal or Bank'**
  String get withdrawals_sub;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transactions_sub.
  ///
  /// In en, this message translates to:
  /// **'View all your transactions'**
  String get transactions_sub;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @theme_select.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get theme_select;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @language_changed.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {lang} ✅'**
  String language_changed(Object lang);

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clear_cache;

  /// No description provided for @clear_cache_sub.
  ///
  /// In en, this message translates to:
  /// **'Remove temporary files, cached images, and uploaded media'**
  String get clear_cache_sub;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @help_sub.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get help_sub;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @about_sub.
  ///
  /// In en, this message translates to:
  /// **'App information and version'**
  String get about_sub;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_sub.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get delete_account_sub;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get logout_sub;

  /// No description provided for @title_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get title_edit_profile;

  /// No description provided for @title_two_factor_verification.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Verification'**
  String get title_two_factor_verification;

  /// No description provided for @title_reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get title_reset_password;

  /// No description provided for @title_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get title_forgot_password;

  /// No description provided for @title_invite_friends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get title_invite_friends;

  /// No description provided for @title_blogs.
  ///
  /// In en, this message translates to:
  /// **'Blogs'**
  String get title_blogs;

  /// No description provided for @title_my_account.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get title_my_account;

  /// No description provided for @title_favorite_users.
  ///
  /// In en, this message translates to:
  /// **'Favorite Users'**
  String get title_favorite_users;

  /// No description provided for @title_social_links.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get title_social_links;

  /// No description provided for @title_user_profile.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s Profile'**
  String title_user_profile(Object username);

  /// No description provided for @error_load_favorites.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites'**
  String get error_load_favorites;

  /// No description provided for @removed_from_favorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removed_from_favorites;

  /// No description provided for @error_with_message.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error_with_message(Object message);

  /// No description provided for @load_more.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get load_more;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @update_password.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get update_password;

  /// No description provided for @choose_file_type.
  ///
  /// In en, this message translates to:
  /// **'Choose File Type'**
  String get choose_file_type;

  /// No description provided for @image_gallery.
  ///
  /// In en, this message translates to:
  /// **'Image Gallery'**
  String get image_gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @video_gallery.
  ///
  /// In en, this message translates to:
  /// **'Video Gallery'**
  String get video_gallery;

  /// No description provided for @video_camera.
  ///
  /// In en, this message translates to:
  /// **'Video Camera'**
  String get video_camera;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @save_profile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get save_profile;

  /// No description provided for @select_label.
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String select_label(Object label);

  /// No description provided for @update_profile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get update_profile;

  /// No description provided for @send_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get send_verification_code;

  /// No description provided for @no_blogs_found.
  ///
  /// In en, this message translates to:
  /// **'No blogs found.'**
  String get no_blogs_found;

  /// No description provided for @article_not_found.
  ///
  /// In en, this message translates to:
  /// **'Article not found'**
  String get article_not_found;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @copy_profile_link.
  ///
  /// In en, this message translates to:
  /// **'Copy Profile Link'**
  String get copy_profile_link;

  /// No description provided for @link_copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
  String get link_copied;

  /// No description provided for @share_link.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get share_link;

  /// No description provided for @enter_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email/phone.'**
  String get enter_verification_code;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @failed_update_online_status.
  ///
  /// In en, this message translates to:
  /// **'Failed to update online status. Please try again.'**
  String get failed_update_online_status;

  /// No description provided for @failed_update_profile_visibility.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile visibility. Please try again.'**
  String get failed_update_profile_visibility;

  /// No description provided for @failed_update_match_visibility.
  ///
  /// In en, this message translates to:
  /// **'Failed to update match visibility. Please try again.'**
  String get failed_update_match_visibility;

  /// No description provided for @help_support.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help_support;

  /// No description provided for @need_help.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get need_help;

  /// No description provided for @contact_email.
  ///
  /// In en, this message translates to:
  /// **'📧 Email: support@staralign.me'**
  String get contact_email;

  /// No description provided for @contact_website.
  ///
  /// In en, this message translates to:
  /// **'🌐 Website: www.staralign.me/help'**
  String get contact_website;

  /// No description provided for @check_faq.
  ///
  /// In en, this message translates to:
  /// **'You can also check our FAQ section or contact us through the app.'**
  String get check_faq;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @about_tagline.
  ///
  /// In en, this message translates to:
  /// **'QuickDate - Find your perfect match!'**
  String get about_tagline;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 StarAlign. All rights reserved.'**
  String get copyright;

  /// No description provided for @account_deleted_success.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get account_deleted_success;

  /// No description provided for @failed_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get failed_delete_account;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear_cache_title.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache?'**
  String get clear_cache_title;

  /// No description provided for @clear_cache_body.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all cached data, including uploaded files, images and temporary media. Are you sure?'**
  String get clear_cache_body;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cache_cleared_success.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cache_cleared_success;

  /// No description provided for @cache_cleared_simulated.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared (simulated on web)'**
  String get cache_cleared_simulated;

  /// No description provided for @logged_out_success.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logged_out_success;

  /// No description provided for @failed_logout.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout. Please try again.'**
  String get failed_logout;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to continue finding partner.'**
  String get login_subtitle;

  /// No description provided for @email_verified_success.
  ///
  /// In en, this message translates to:
  /// **'✅ Email verified successfully!'**
  String get email_verified_success;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
