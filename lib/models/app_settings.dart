import 'model_utils.dart';

/// Application settings stored locally. Only the *preference* for biometric
/// login is stored - never any biometric data.
class AppSettings {
  const AppSettings({
    this.businessName = 'أثاثي',
    this.businessSubtitle = 'إدارة بيع الأثاث المستعمل',
    this.currency = 'د.ت',
    this.lowStockThreshold = 3,
    this.biometricEnabled = false,
    this.biometricPrompted = false,
    this.openingBalance = 0,
    this.lastBackupAt,
  });

  final String businessName;
  final String businessSubtitle;
  final String currency;

  /// A product with quantity <= this value (and > 0) is "كمية منخفضة".
  final int lowStockThreshold;
  final bool biometricEnabled;

  /// True once the "enable biometric login?" question was shown.
  final bool biometricPrompted;

  /// Cash in the drawer when the owner started using the app (الحسابات).
  final double openingBalance;
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    String? businessName,
    String? businessSubtitle,
    String? currency,
    int? lowStockThreshold,
    bool? biometricEnabled,
    bool? biometricPrompted,
    double? openingBalance,
    DateTime? lastBackupAt,
  }) =>
      AppSettings(
        businessName: businessName ?? this.businessName,
        businessSubtitle: businessSubtitle ?? this.businessSubtitle,
        currency: currency ?? this.currency,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        biometricPrompted: biometricPrompted ?? this.biometricPrompted,
        openingBalance: openingBalance ?? this.openingBalance,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'businessSubtitle': businessSubtitle,
        'currency': currency,
        'lowStockThreshold': lowStockThreshold,
        'biometricEnabled': biometricEnabled,
        'biometricPrompted': biometricPrompted,
        'openingBalance': openingBalance,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    const d = AppSettings();
    return AppSettings(
      businessName: map['businessName'] as String? ?? d.businessName,
      businessSubtitle:
          map['businessSubtitle'] as String? ?? d.businessSubtitle,
      currency: map['currency'] as String? ?? d.currency,
      lowStockThreshold:
          asInt(map['lowStockThreshold'], d.lowStockThreshold),
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      biometricPrompted: map['biometricPrompted'] as bool? ?? false,
      openingBalance: asDouble(map['openingBalance']),
      lastBackupAt: asDateOrNull(map['lastBackupAt']),
    );
  }
}
