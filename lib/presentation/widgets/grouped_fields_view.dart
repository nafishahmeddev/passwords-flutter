import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/account_field.dart';
import '../../business/providers/account_detail_provider.dart';
import '../utils/field_grouping_utils.dart';
import 'field_views/credential_field_view.dart';
import 'field_views/password_field_view.dart';
import 'field_views/text_field_view.dart';
import 'field_views/website_field_view.dart';
import 'otp_field_view.dart';

/// Widget that displays a group of fields with a header and organized layout
class FieldGroupWidget extends StatelessWidget {
  final FieldGroup group;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const FieldGroupWidget({
    super.key,
    required this.group,
    this.isExpanded = true,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(isExpanded ? 0 : 16),
                bottomRight: Radius.circular(isExpanded ? 0 : 16),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: group.color.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(isExpanded ? 0 : 16),
                    bottomRight: Radius.circular(isExpanded ? 0 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: group.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(group.icon, color: group.color, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${group.fieldCount} ${group.fieldCount == 1 ? 'field' : 'fields'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleExpanded != null)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),

            // Group Content
            if (isExpanded) ...[
              // Fields List
              ...group.fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                final isLast = index == group.fields.length - 1;

                return Column(
                  children: [
                    _buildFieldWidget(field),
                    if (!isLast)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                  ],
                );
              }).toList(),

              // Bottom padding
              SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWidget(AccountField field) {
    switch (field.type) {
      case AccountFieldType.credential:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: CredentialFieldView(field: field),
        );
      case AccountFieldType.password:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: PasswordFieldView(field: field),
        );
      case AccountFieldType.text:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: TextFieldView(field: field),
        );
      case AccountFieldType.website:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: WebsiteFieldView(field: field),
        );
      case AccountFieldType.otp:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Consumer<AccountDetailProvider>(
            builder: (context, provider, child) {
              return OtpFieldView(
                field: field,
                onFieldUpdate: (updatedField) {
                  provider.updateField(updatedField);
                },
              );
            },
          ),
        );
    }
  }
}

/// Widget that displays all field groups in an organized manner
class GroupedFieldsView extends StatefulWidget {
  final List<AccountField> fields;

  const GroupedFieldsView({super.key, required this.fields});

  @override
  State<GroupedFieldsView> createState() => _GroupedFieldsViewState();
}

class _GroupedFieldsViewState extends State<GroupedFieldsView> {
  final Set<String> _expandedGroups = <String>{};

  @override
  void initState() {
    super.initState();
    // Groups will be expanded by default in the build method
  }

  void _toggleGroup(String groupKey) {
    setState(() {
      if (_expandedGroups.contains(groupKey)) {
        _expandedGroups.remove(groupKey);
      } else {
        _expandedGroups.add(groupKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = FieldGroupingUtils.groupFields(widget.fields, context);
    final sortedGroups = FieldGroupingUtils.getSortedGroups(groups);

    // Initialize expanded groups if empty
    if (_expandedGroups.isEmpty) {
      _expandedGroups.addAll(groups.keys);
    }

    if (sortedGroups.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedGroups.map((group) {
        final groupKey = _getGroupKey(group);
        final isExpanded = _expandedGroups.contains(groupKey);

        return FieldGroupWidget(
          group: group,
          isExpanded: isExpanded,
          onToggleExpanded: () => _toggleGroup(groupKey),
        );
      }).toList(),
    );
  }

  String _getGroupKey(FieldGroup group) {
    // Generate a key based on the group's title for tracking expansion state
    return group.title.toLowerCase().replaceAll(' ', '_');
  }
}
