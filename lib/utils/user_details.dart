//user details dart
class MediaFile {
  String? id;
  String? full;
  String? videoFile;
  String? avater;
  String? urlFile;
  String isVideo;

  MediaFile({this.id, this.full, this.videoFile, this.avater, this.urlFile, this.isVideo = "0"});

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      full: json['full'],
      videoFile: json['video_file'],
      avater: json['avater'],
      isVideo: json['is_video'] ?? "0",
    );
  }
}

class UserDetails {
  // ✅ Existing fields (unchanged)
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
  static List<MediaFile> mediaFiles = [];

  static String lat = "";
  static String lng = "";

  static String country_txt = ""; // User's country name for display
  static String phone = ""; // User's phone number

  static int filterOptionAgeMin = 18;
  static int filterOptionAgeMax = 75;
  static String filterOptionGender = "4525,4526";
  static bool filterOptionIsOnline = false;
  static String filterOptionDistance = "35";
  static String filterOptionLanguage = "english";
static String about='';
  // ✅ New fields from backend (added)
  static String firstName = "";
  static String lastName = "";
  static String birthday = "";
  static String gender = "";
  static String genderTxt = "";
  static String relationship = "";
  static String workStatus = "";
  static String education = "";
  static String ethnicity = "";
  static String body = "";
  static String children = "";
  static String pets = "";
  static String liveWith = "";
  static String car = "";
  static String religion = "";
  static String smoke = "";
  static String drink = "";
  static String travel = "";
  static String music = "";
  static String dish = "";
  static String song = "";
  static String hobby = "";
  static String city = "";
  static String sport = "";
  static String book = "";
  static String movie = "";
  static String colour = "";
  static String tv = "";
  static String lookingFor = "";

  // Social links
  static String facebook = "";
  static String google = "";
  static String twitter = "";
  static String linkedin = "";
  static String instagram = "";
  static String okru = "";
  static String mailru = "";
  static String discord = "";
  static String wechat = "";
  static String qq = "";
  static String website = "";

  // App metadata
  static int profileCompletion = 0;
  static List<String> profileCompletionMissing = [];
  static String balance = "0.00";
  static String proTime = "0";
  static String lastSeen = "";
  static String registered = "";
  static String emailCode = "";
  static String src = "";
  static String ipAddress = "";
  static String socialLogin = "0";
  static String createdAt = "";
  static String updatedAt = "";
  static String deletedAt = "";

  static void clearAll() {
    // ✅ Keep existing clears intact
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
    country_txt = "";
    phone = "";
    mediaFiles = [];
    filterOptionAgeMin = 18;
    filterOptionAgeMax = 75;
    filterOptionGender = "4525,4526";
    filterOptionIsOnline = false;
    filterOptionDistance = "35";
    filterOptionLanguage = "english";

    // ✅ Clear new fields too
    firstName = "";
    lastName = "";
    birthday = "";
    gender = "";
    genderTxt = "";
    relationship = "";
    workStatus = "";
    education = "";
    ethnicity = "";
    body = "";
    children = "";
    pets = "";
    liveWith = "";
    car = "";
    religion = "";
    smoke = "";
    drink = "";
    travel = "";
    music = "";
    dish = "";
    song = "";
    hobby = "";
    city = "";
    sport = "";
    book = "";
    movie = "";
    colour = "";
    tv = "";

    facebook = "";
    google = "";
    twitter = "";
    linkedin = "";
    instagram = "";
    okru = "";
    mailru = "";
    discord = "";
    wechat = "";
    qq = "";
    website = "";

    profileCompletion = 0;
    profileCompletionMissing = [];
    balance = "0.00";
    proTime = "0";
    lastSeen = "";
    registered = "";
    emailCode = "";
    src = "";
    ipAddress = "";
    socialLogin = "0";
    createdAt = "";
    updatedAt = "";
    deletedAt = "";
  }
}
class MyUserInfo {
  String firstName;
  String lastName;
  String hobby;
  String music;
  String movie;
  String city;
  String country;
  String birthday;
  String gender;
  String relationship;
  String workStatus;
  String education;
  List<MediaFile> mediaFiles;
  String about;

  MyUserInfo({
    this.firstName = '',
    this.lastName = '',
    this.hobby = '',
    this.music = '',
    this.movie = '',
    this.city = '',
    this.country = '',
    this.birthday = '',
    this.gender = '',
    this.relationship = '',
    this.workStatus = '',
    this.education = '',
    this.mediaFiles = const [],
    this.about = '',
  });
}

// ✅ Existing User class remains completely untouched
class User {
  final int id;
  final String username;
  final String avatar;
  final String fullName;
  final String country;

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
      fullName: (json['first_name'] ?? '') + ' ' + (json['last_name'] ?? ''),
      country: json['country_txt'] ?? '',
    );
  }
}
