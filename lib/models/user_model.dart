class UserModel {
  final String id;
  String name;
  String emailOrMobile;
  bool isPremium;
  DateTime joinedDate;

  UserModel({
    required this.id,
    required this.name,
    required this.emailOrMobile,
    this.isPremium = false,
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emailOrMobile': emailOrMobile,
        'isPremium': isPremium,
        'joinedDate': joinedDate.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        emailOrMobile: json['emailOrMobile'] as String,
        isPremium: json['isPremium'] as bool? ?? false,
        joinedDate: json['joinedDate'] != null
            ? DateTime.parse(json['joinedDate'] as String)
            : null,
      );
}
