import 'package:flutter/material.dart';
import '../../../../data/models/account_field.dart';
import '../../../utils/field_grouping_utils.dart';
import 'credential_field_view.dart';
import 'password_field_view.dart';
import 'text_field_view.dart';
import 'website_field_view.dart';
import 'otp_field_view.dart';
import 'package:provider/provider.dart';
import '../../../../business/providers/account_detail_provider.dart';

/// A modern styled widget that displays all field groups in a clean layout
class SimplifiedGroupedFieldsView extends StatelessWidget {
  final List<AccountField> fields;

  const SimplifiedGroupedFieldsView({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final groups = FieldGroupingUtils.groupFields(fields, context);
    final sortedGroups = FieldGroupingUtils.getSortedGroups(groups);

    if (sortedGroups.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        final group = sortedGroups[index];
        if (group.isEmpty) return SizedBox.shrink();

        return ModernGroupSection(
          group: group,
          isLastGroup: index == sortedGroups.length - 1,
        );
      },
    );
  }
}

/// A modern-style group section with header and fields
class ModernGroupSection extends StatelessWidget {
  final FieldGroup group;
  final bool isLastGroup;

  const ModernGroupSection({
    super.key,
    required this.group,
    this.isLastGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon like settings screen
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              right: 4,
              top: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                // Icon container like in settings screen
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    group.icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),

                // Section title like in settings screen
                Text(
                  group.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Card container matching settings and list screens style
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Fields with consistent styling
                ...group.fields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  final isLast = index == group.fields.length - 1;

                  return Column(
                    children: [
                      _buildFieldWidget(field, index),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Bottom spacing unless it's the last group
          if (!isLastGroup) SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(AccountField field, int index) {
    // No need for border radius calculation as we're handling that with the Card wrapper
    // and using dividers between items

    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialFieldView(field: field);
      case AccountFieldType.password:
        return PasswordFieldView(field: field);
      case AccountFieldType.text:
        return TextFieldView(field: field);
      case AccountFieldType.website:
        return WebsiteFieldView(field: field);
      case AccountFieldType.otp:
        return Consumer<AccountDetailProvider>(
          builder: (context, provider, child) {
            return OtpFieldView(
              field: field,
              onFieldUpdate: (updatedField) {
                provider.updateField(updatedField);
              },
            );
          },
        );
    }
  }
}
