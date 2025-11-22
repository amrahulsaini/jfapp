class PlanModel {
  final int planId;
  final String planName;
  final String planType;
  final double price;
  final int? viewsLimit;
  final Map<String, dynamic> features;

  PlanModel({
    required this.planId,
    required this.planName,
    required this.planType,
    required this.price,
    this.viewsLimit,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      planId: json['plan_id'],
      planName: json['plan_name'],
      planType: json['plan_type'],
      price: double.parse(json['price'].toString()),
      viewsLimit: json['views_limit'],
      features: json['features'] is String 
          ? {} 
          : Map<String, dynamic>.from(json['features'] ?? {}),
    );
  }
}

class PurchaseModel {
  final int purchaseId;
  final String planName;
  final String planType;
  final int? viewsRemaining;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final Map<String, dynamic> features;

  PurchaseModel({
    required this.purchaseId,
    required this.planName,
    required this.planType,
    this.viewsRemaining,
    required this.purchaseDate,
    this.expiryDate,
    required this.features,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      purchaseId: json['purchase_id'],
      planName: json['plan_name'],
      planType: json['plan_type'],
      viewsRemaining: json['views_remaining'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      features: json['features'] is String 
          ? {} 
          : Map<String, dynamic>.from(json['features'] ?? {}),
    );
  }

  bool get isPremium => planType == 'premium';
  bool get hasUnlimitedViews => viewsRemaining == null;
  bool get canContactSupport => features['can_contact_support'] == true;
  bool get canRequestEdits => features['can_request_edits'] == true;
}
