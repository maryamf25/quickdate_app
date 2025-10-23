class UserDetails {
  static String accessToken = "";
  static int userId = 0;
  static String username = "";
  static String fullName = "";
  static String password = "";
  static String email = "";
  static String cookie = "";
  static String status = "";
  static String avatar = "";
  static String cover = "";
  static String deviceId = "";
  static String langName = "";
  static String isPro = "";
  static String url = "";
  static String facebook= "";
  static String google = "";
  static String twitter = "";
  static String linkedin = "";
  static String instagram = "";
  static String discord = "";
  static String okru = "";
  static String mailru = "";
  static String wechat = "";
  static String qq = "";
  static String website = "";
  static String lat = "";
  static String lng = "";
  static List<Map<String, dynamic>> blockedUsers = [];

  // ✅ Add these fields
  static String country_txt = ""; // User's country name for display
  static String phone = ""; // User's phone number

  static int filterOptionAgeMin = 18;
  static int filterOptionAgeMax = 75;
  static String filterOptionGender = "4525,4526";
  static bool filterOptionIsOnline = false;
  static String filterOptionDistance = "35";
  static String filterOptionLanguage = "english";

  // get name => null; // This getter is unusual for a static class, consider removing or making it static if needed.

  static void clearAll() {
    accessToken = "";
    userId = 0;
    username = "";
    fullName = "";
    password = "";
    email = "";
    cookie = "";
    status = "";
    avatar = "";
    cover = "";
    deviceId = "";
    langName = "";
    isPro = "";
    url = "";
    lat = "";
    lng = "";
    facebook = "";
    google = "";
    twitter = "";
    linkedin = "";
    instagram = "";
    discord = "";
    okru = "";
    mailru = "";
    wechat = "";
    qq = "";
    website = "";

    // ✅ Clear new fields as well
    country_txt = "";
    phone = "";

    filterOptionAgeMin = 18;
    filterOptionAgeMax = 75;
    filterOptionGender = "4525,4526";
    filterOptionIsOnline = false;
    filterOptionDistance = "35";
    filterOptionLanguage = "english";
  }
}

// Your existing User class (no changes needed here, just for context)
class User {
  final int id;
  final String username;
  final String avatar; // Corrected from avater in your JSON field
  final String fullName;
  final String country; // This corresponds to country_txt from JSON

  User({
    required this.id,
    required this.username,
    required this.avatar,
    required this.fullName,
    required this.country,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      avatar: json['avater'] ?? '',
      // API still uses 'avater', so keep this here
      fullName: (json['first_name'] ?? '') + ' ' + (json['last_name'] ?? ''),
      country: json['country_txt'] ?? '',
    );
  }
}
