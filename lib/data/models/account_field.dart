import 'dart:convert';
import 'package:uuid/uuid.dart';

enum AccountFieldType {
  credential,
  password,
  text,
  website,
  otp;

  @override
  String toString() => name;

  static AccountFieldType fromString(String value) {
    return AccountFieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AccountFieldType.text,
    );
  }
}

class AccountField {
  String id;
  String accountId;
  String label;
  AccountFieldType type; // Using enum directly
  bool requiredField;
  int order;
  Map<String, String> metadata; // New metadata field

  AccountField({
    String? id,
    required this.accountId,
    required this.label,
    required this.type,
    this.requiredField = false,
    this.order = 0,
    Map<String, String>? metadata,
  }) : id = id ?? const Uuid().v4(),
       metadata = metadata ?? {};

  // Helper getters and setters for type safety
  AccountFieldType get fieldType => type;
  set fieldType(AccountFieldType value) => type = value;

  // Helper methods for metadata
  String getMetadata(String key, [String defaultValue = '']) {
    return metadata[key] ?? defaultValue;
  }

  void setMetadata(String key, String value) {
    metadata[key] = value;
  }

  void setMetadataMap(Map<String, String> newMetadata) {
    metadata.clear();
    metadata.addAll(newMetadata);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'accountId': accountId,
    'label': label,
    'type': type.name,
    'required': requiredField ? 1 : 0,
    'fieldOrder': order,
    'metadata': metadata.isEmpty ? null : jsonEncode(metadata),
  };

  factory AccountField.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedMetadata = {};

    if (map['metadata'] != null && map['metadata'] is String) {
      try {
        final decoded = jsonDecode(map['metadata'] as String);
        if (decoded is Map) {
          parsedMetadata = Map<String, String>.from(decoded);
        }
      } catch (e) {
        // If JSON parsing fails, keep empty metadata
        parsedMetadata = {};
      }
    }

    return AccountField(
      id: map['id'] as String,
      accountId: map['accountId'] as String,
      label: map['label'],
      type: AccountFieldType.fromString(map['type']),
      requiredField: map['required'] == 1,
      order: map['fieldOrder'] ?? 0,
      metadata: parsedMetadata,
    );
  }

  AccountField copyWith({
    Object? id,
    Object? accountId,
    String? label,
    AccountFieldType? type,
    bool? requiredField,
    int? order,
    Map<String, String>? metadata,
  }) {
    return AccountField(
      id: id != null ? id as String : this.id,
      accountId: accountId != null ? accountId as String : this.accountId,
      label: label ?? this.label,
      type: type ?? this.type,
      requiredField: requiredField ?? this.requiredField,
      order: order ?? this.order,
      metadata: metadata ?? this.metadata,
    );
  }
}
