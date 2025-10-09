import 'dart:convert';

enum AccountFieldType {
  credential,
  password,
  text,
  website;

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
  int? id;
  int accountId;
  String label;
  AccountFieldType type; // Using enum directly
  bool requiredField;
  int order;
  Map<String, String> metadata; // New metadata field

  AccountField({
    this.id,
    required this.accountId,
    required this.label,
    required this.type,
    this.requiredField = false,
    this.order = 0,
    Map<String, String>? metadata,
  }) : metadata = metadata ?? {};

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
      id: map['id'],
      accountId: map['accountId'],
      label: map['label'],
      type: AccountFieldType.fromString(map['type']),
      requiredField: map['required'] == 1,
      order: map['fieldOrder'] ?? 0,
      metadata: parsedMetadata,
    );
  }
}
