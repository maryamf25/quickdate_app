// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'QuickDate';

  @override
  String get tab_match => 'Match';

  @override
  String get tab_trending => 'Trending';

  @override
  String get tab_alerts => 'Alerts';

  @override
  String get tab_chats => 'Chats';

  @override
  String get tab_settings => 'Settings';

  @override
  String get settings_title => 'Settings';

  @override
  String get general => 'General';

  @override
  String get my_account => 'My Account';

  @override
  String get my_account_sub => 'Manage your profile and settings';

  @override
  String get social_links => 'Social Links';

  @override
  String get social_links_sub => 'Connect your social media accounts';

  @override
  String get blocked_users => 'Blocked Users';

  @override
  String get blocked_users_sub => 'Manage blocked users';

  @override
  String get my_affiliates => 'My Affiliates';

  @override
  String get my_affiliates_sub => 'Earn rewards for referrals';

  @override
  String get messenger => 'Messenger';

  @override
  String get show_active => 'Show when you\'re active';

  @override
  String get privacy => 'Privacy';

  @override
  String get show_profile_search => 'Show my profile on search engines?';

  @override
  String get show_profile_random => 'Show my profile to random users?';

  @override
  String get show_profile_match => 'Show my profile in the match page?';

  @override
  String get confirm_friend => 'Confirm friend requests before accepting?';

  @override
  String get security => 'Security';

  @override
  String get password => 'Password';

  @override
  String get password_sub => 'Change your account password';

  @override
  String get two_factor => 'Two-Factor Authentication';

  @override
  String get manage_sessions => 'Manage Sessions';

  @override
  String get payments => 'Payments';

  @override
  String get withdrawals => 'Withdrawals';

  @override
  String get withdrawals_sub => 'Withdraw your earnings via PayPal or Bank';

  @override
  String get transactions => 'Transactions';

  @override
  String get transactions_sub => 'View all your transactions';

  @override
  String get display => 'Display';

  @override
  String get theme => 'Theme';

  @override
  String get theme_select => 'Select Theme';

  @override
  String get theme_system => 'System Default';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String language_changed(Object lang) {
    return 'Language changed to $lang ✅';
  }

  @override
  String get storage => 'Storage';

  @override
  String get clear_cache => 'Clear Cache';

  @override
  String get clear_cache_sub =>
      'Remove temporary files, cached images, and uploaded media';

  @override
  String get support => 'Support';

  @override
  String get help => 'Help';

  @override
  String get help_sub => 'Get help and support';

  @override
  String get about => 'About';

  @override
  String get about_sub => 'App information and version';

  @override
  String get delete_account => 'Delete Account';

  @override
  String get delete_account_sub => 'Permanently delete your account';

  @override
  String get logout => 'Logout';

  @override
  String get logout_sub => 'Sign out of your account';

  @override
  String get title_edit_profile => 'Edit Profile';

  @override
  String get title_two_factor_verification => 'Two-Factor Verification';

  @override
  String get title_reset_password => 'Reset Password';

  @override
  String get title_forgot_password => 'Forgot Password';

  @override
  String get title_invite_friends => 'Invite Friends';

  @override
  String get title_blogs => 'Blogs';

  @override
  String get title_my_account => 'My Account';

  @override
  String get title_favorite_users => 'Favorite Users';

  @override
  String get title_social_links => 'Social Links';

  @override
  String title_user_profile(Object username) {
    return '$username\'s Profile';
  }

  @override
  String get error_load_favorites => 'Failed to load favorites';

  @override
  String get removed_from_favorites => 'Removed from favorites';

  @override
  String error_with_message(Object message) {
    return 'Error: $message';
  }

  @override
  String get load_more => 'Load More';

  @override
  String get common_save => 'Save';

  @override
  String get common_ok => 'OK';

  @override
  String get update_password => 'Update Password';

  @override
  String get choose_file_type => 'Choose File Type';

  @override
  String get image_gallery => 'Image Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get video_gallery => 'Video Gallery';

  @override
  String get video_camera => 'Video Camera';

  @override
  String get birthday => 'Birthday';

  @override
  String get save_profile => 'Save Profile';

  @override
  String select_label(Object label) {
    return 'Select $label';
  }

  @override
  String get update_profile => 'Update Profile';

  @override
  String get send_verification_code => 'Send Verification Code';

  @override
  String get no_blogs_found => 'No blogs found.';

  @override
  String get article_not_found => 'Article not found';

  @override
  String get back => 'Back';

  @override
  String get copy_profile_link => 'Copy Profile Link';

  @override
  String get link_copied => 'Link copied to clipboard!';

  @override
  String get share_link => 'Share Link';

  @override
  String get enter_verification_code =>
      'Enter the verification code sent to your email/phone.';

  @override
  String get verify => 'Verify';

  @override
  String get failed_update_online_status =>
      'Failed to update online status. Please try again.';

  @override
  String get failed_update_profile_visibility =>
      'Failed to update profile visibility. Please try again.';

  @override
  String get failed_update_match_visibility =>
      'Failed to update match visibility. Please try again.';

  @override
  String get help_support => 'Help & Support';

  @override
  String get need_help => 'Need help?';

  @override
  String get contact_email => '📧 Email: support@staralign.me';

  @override
  String get contact_website => '🌐 Website: www.staralign.me/help';

  @override
  String get check_faq =>
      'You can also check our FAQ section or contact us through the app.';

  @override
  String get close => 'Close';

  @override
  String get about_tagline => 'QuickDate - Find your perfect match!';

  @override
  String get copyright => '© 2025 StarAlign. All rights reserved.';

  @override
  String get account_deleted_success => 'Account deleted successfully';

  @override
  String get failed_delete_account =>
      'Failed to delete account. Please try again.';

  @override
  String get logout_confirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear_cache_title => 'Clear Cache?';

  @override
  String get clear_cache_body =>
      'This will permanently delete all cached data, including uploaded files, images and temporary media. Are you sure?';

  @override
  String get delete => 'Delete';

  @override
  String get cache_cleared_success => 'Cache cleared successfully';

  @override
  String get cache_cleared_simulated => 'Cache cleared (simulated on web)';

  @override
  String get logged_out_success => 'Logged out successfully';

  @override
  String get failed_logout => 'Failed to logout. Please try again.';

  @override
  String get login_subtitle => 'Login to continue finding partner.';

  @override
  String get email_verified_success => '✅ Email verified successfully!';

  @override
  String get affiliates_earn_message =>
      'Earn up to for each user you refer to us!';

  @override
  String get affiliates_share_message =>
      'Share this link with your friends and earn rewards!';
}
