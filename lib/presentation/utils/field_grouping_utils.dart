import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';

/// Utility class for grouping and organizing account fields by type
class FieldGroupingUtils {
  /// Groups fields by their type and returns a map with display information
  static Map<String, FieldGroup> groupFields(
    List<AccountField> fields,
    BuildContext context,
  ) {
    final Map<String, FieldGroup> groups = {};

    for (final field in fields) {
      final groupInfo = _getGroupInfo(field.type, context);
      final groupKey = groupInfo.key;

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = FieldGroup(
          title: groupInfo.title,
          icon: groupInfo.icon,
          fields: [],
          order: groupInfo.order,
        );
      }

      groups[groupKey]!.fields.add(field);
    }

    // Sort fields within each group by their order
    for (final group in groups.values) {
      group.fields.sort((a, b) => a.order.compareTo(b.order));
    }

    return groups;
  }

  /// Returns groups sorted by their display order
  static List<FieldGroup> getSortedGroups(Map<String, FieldGroup> groups) {
    final sortedGroups = groups.values.toList();
    sortedGroups.sort((a, b) => a.order.compareTo(b.order));
    return sortedGroups;
  }

  /// Gets group information for a specific field type
  static _GroupInfo _getGroupInfo(AccountFieldType type, BuildContext context) {
    switch (type) {
      case AccountFieldType.credential:
        return _GroupInfo(
          key: 'credentials',
          title: 'CREDENTIALS',
          icon: Icons.account_circle_outlined,
          order: 1,
        );
      case AccountFieldType.password:
        return _GroupInfo(
          key: 'passwords',
          title: 'PASSWORDS',
          icon: Icons.lock_outline,
          order: 2,
        );
      case AccountFieldType.website:
        return _GroupInfo(
          key: 'websites',
          title: 'WEBSITES',
          icon: Icons.language_outlined,
          order: 3,
        );
      case AccountFieldType.otp:
        return _GroupInfo(
          key: 'otp',
          title: '2FA / OTP',
          icon: Icons.security_outlined,
          order: 4,
        );
      case AccountFieldType.text:
        return _GroupInfo(
          key: 'general',
          title: 'INFORMATION',
          icon: Icons.description_outlined,
          order: 5,
        );
    }
  }
}

/// Represents a group of fields with display information
class FieldGroup {
  final String title;
  final IconData icon;
  final List<AccountField> fields;
  final int order;

  FieldGroup({
    required this.title,
    required this.icon,
    required this.fields,
    required this.order,
  });

  /// Returns the number of fields in this group
  int get fieldCount => fields.length;

  /// Returns true if this group has no fields
  bool get isEmpty => fields.isEmpty;

  /// Returns true if this group has fields
  bool get isNotEmpty => fields.isNotEmpty;
}

/// Internal class for group metadata
class _GroupInfo {
  final String key;
  final String title;
  final IconData icon;
  final int order;

  _GroupInfo({
    required this.key,
    required this.title,
    required this.icon,
    required this.order,
  });
}
