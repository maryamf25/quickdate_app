// lib/models/payment_models.dart

/// Generic payment transaction model
class PaymentTransaction {
  final String id;
  final String provider;
  final String status; // 'pending', 'success', 'failed', 'cancelled'
  final double amount;
  final String currency;
  final String email;
  final String planName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? reference; // Provider's transaction reference
  final String? error;

  PaymentTransaction({
    required this.id,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    required this.email,
    required this.planName,
    required this.createdAt,
    this.completedAt,
    this.reference,
    this.error,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      provider: json['provider'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      email: json['email'] ?? '',
      planName: json['planName'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      reference: json['reference'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'status': status,
    'amount': amount,
    'currency': currency,
    'email': email,
    'planName': planName,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'reference': reference,
    'error': error,
  };
}

/// Paystack response models
class PaystackInitResponse {
  final bool status;
  final String message;
  final PaystackInitData? data;

  PaystackInitResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PaystackInitResponse.fromJson(Map<String, dynamic> json) {
    return PaystackInitResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaystackInitData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class PaystackInitData {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaystackInitData({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory PaystackInitData.fromJson(Map<String, dynamic> json) {
    return PaystackInitData(
      authorizationUrl: json['authorization_url'] ?? json['authorizationUrl'] ?? '',
      accessCode: json['access_code'] ?? json['accessCode'] ?? '',
      reference: json['reference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'authorization_url': authorizationUrl,
    'access_code': accessCode,
    'reference': reference,
  };
}

/// SecurionPay response models
class SecurionPayResponse {
  final String id;
  final String status;
  final double amount;
  final String currency;

  SecurionPayResponse({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
  });

  factory SecurionPayResponse.fromJson(Map<String, dynamic> json) {
    return SecurionPayResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'amount': amount,
    'currency': currency,
  };
}

/// IyziPay response models
class IyziPayResponse {
  final String status;
  final String paymentId;
  final String checkoutFormContent;
  final String? paymentUrl;

  IyziPayResponse({
    required this.status,
    required this.paymentId,
    required this.checkoutFormContent,
    this.paymentUrl,
  });

  factory IyziPayResponse.fromJson(Map<String, dynamic> json) {
    return IyziPayResponse(
      status: json['status'] ?? '',
      paymentId: json['paymentId'] ?? json['payment_id'] ?? '',
      checkoutFormContent: json['checkoutFormContent'] ?? json['checkout_form_content'] ?? '',
      paymentUrl: json['paymentUrl'] ?? json['payment_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'paymentId': paymentId,
    'checkoutFormContent': checkoutFormContent,
    'paymentUrl': paymentUrl,
  };
}

/// AamarPay response models
class AamarPayResponse {
  final String status;
  final String orderId;
  final String paymentUrl;
  final String? reference;

  AamarPayResponse({
    required this.status,
    required this.orderId,
    required this.paymentUrl,
    this.reference,
  });

  factory AamarPayResponse.fromJson(Map<String, dynamic> json) {
    return AamarPayResponse(
      status: json['status'] ?? '',
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      paymentUrl: json['paymentUrl'] ?? json['payment_url'] ?? '',
      reference: json['reference'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'orderId': orderId,
    'paymentUrl': paymentUrl,
    'reference': reference,
  };
}

/// Flutterwave response models
class FlutterwaveResponse {
  final String status;
  final FlutterwaveData? data;

  FlutterwaveResponse({
    required this.status,
    this.data,
  });

  factory FlutterwaveResponse.fromJson(Map<String, dynamic> json) {
    return FlutterwaveResponse(
      status: json['status'] ?? '',
      data: json['data'] != null ? FlutterwaveData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'data': data?.toJson(),
  };
}

class FlutterwaveData {
  final String link;
  final String txRef;
  final String reference;

  FlutterwaveData({
    required this.link,
    required this.txRef,
    required this.reference,
  });

  factory FlutterwaveData.fromJson(Map<String, dynamic> json) {
    return FlutterwaveData(
      link: json['link'] ?? '',
      txRef: json['tx_ref'] ?? json['txRef'] ?? '',
      reference: json['reference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'link': link,
    'tx_ref': txRef,
    'reference': reference,
  };
}

/// Authorize.Net response models
class AuthorizeNetResponse {
  final String transactionId;
  final String refId;
  final Map<String, dynamic> transactionResponse;

  AuthorizeNetResponse({
    required this.transactionId,
    required this.refId,
    required this.transactionResponse,
  });

  factory AuthorizeNetResponse.fromJson(Map<String, dynamic> json) {
    return AuthorizeNetResponse(
      transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
      refId: json['refId'] ?? json['ref_id'] ?? '',
      transactionResponse: json['transactionResponse'] ?? json['transaction_response'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'refId': refId,
    'transactionResponse': transactionResponse,
  };
}

/// LyziPay response models
class LyziPayResponse {
  final String status;
  final String paymentId;
  final String checkoutUrl;

  LyziPayResponse({
    required this.status,
    required this.paymentId,
    required this.checkoutUrl,
  });

  factory LyziPayResponse.fromJson(Map<String, dynamic> json) {
    return LyziPayResponse(
      status: json['status'] ?? '',
      paymentId: json['paymentId'] ?? json['payment_id'] ?? '',
      checkoutUrl: json['checkoutUrl'] ?? json['checkout_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'paymentId': paymentId,
    'checkoutUrl': checkoutUrl,
  };
}

