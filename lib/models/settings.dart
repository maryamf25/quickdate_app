class Settings {
  String emailValidation;
  String verificationOnSignup;
  String emailNotification;
  String activationLimitSystem;
  int maxActivationRequest;
  int activationRequestTimeLimit;
  String specificEmailSignup;

  Settings({
    this.emailValidation = "0",
    this.verificationOnSignup = "0",
    this.emailNotification = "0",
    this.activationLimitSystem = "0",
    this.maxActivationRequest = 0,
    this.activationRequestTimeLimit = 0,
    this.specificEmailSignup = "0"
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
        emailValidation: json['email_validation'] ?? "0",
        verificationOnSignup: json['verification_on_signup'] ?? "0",
        emailNotification: json['email_notification'] ?? "0",
        activationLimitSystem: json['activation_limit_system'] ?? "0",
        maxActivationRequest: int.parse(json['max_activation_request'] ?? "0"),
        activationRequestTimeLimit: int.parse(json['activation_request_time_limit'] ?? "0"),
        specificEmailSignup: json['specific_email_signup'] ?? "0"
    );
  }
}