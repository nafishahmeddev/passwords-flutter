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
          color: groupInfo.color,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (type) {
      case AccountFieldType.credential:
        return _GroupInfo(
          key: 'credentials',
          title: 'Login Credentials',
          icon: Icons.account_circle,
          color: colorScheme.primary,
          order: 1,
        );
      case AccountFieldType.password:
        return _GroupInfo(
          key: 'passwords',
          title: 'Passwords',
          icon: Icons.lock,
          color: colorScheme.secondary,
          order: 2,
        );
      case AccountFieldType.website:
        return _GroupInfo(
          key: 'websites',
          title: 'Websites & URLs',
          icon: Icons.language,
          color: colorScheme.tertiary,
          order: 3,
        );
      case AccountFieldType.otp:
        return _GroupInfo(
          key: 'otp',
          title: 'Two-Factor Authentication',
          icon: Icons.security,
          color: colorScheme.primary.withOpacity(0.8),
          order: 4,
        );
      case AccountFieldType.text:
        return _GroupInfo(
          key: 'general',
          title: 'General Information',
          icon: Icons.description,
          color: colorScheme.outline,
          order: 5,
        );
    }
  }
}

/// Represents a group of fields with display information
class FieldGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<AccountField> fields;
  final int order;

  FieldGroup({
    required this.title,
    required this.icon,
    required this.color,
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
  final Color color;
  final int order;

  _GroupInfo({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.order,
  });
}
