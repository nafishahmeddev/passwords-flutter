import 'package:flutter/material.dart';
import '../../../../data/models/account_field.dart';
import '../../../../business/providers/account_form_provider.dart';
import '../../../utils/field_grouping_utils.dart';
import 'credential_field.dart';
import 'password_field.dart';
import 'text_field.dart';
import 'website_field.dart';
import 'otp_field.dart';

/// A widget that displays form fields in grouped sections for better organization
class GroupedFieldsFormView extends StatelessWidget {
  final List<AccountField> fields;
  final AccountFormProvider formProvider;
  final Function(AccountField) onDeleteField;

  const GroupedFieldsFormView({
    super.key,
    required this.fields,
    required this.formProvider,
    required this.onDeleteField,
  });

  @override
  Widget build(BuildContext context) {
    final groups = FieldGroupingUtils.groupFields(fields, context);
    final sortedGroups = FieldGroupingUtils.getSortedGroups(groups);

    if (sortedGroups.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sortedGroups.length; i++)
          _buildGroupSection(
            context,
            sortedGroups[i],
            i == sortedGroups.length - 1,
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Card(
        elevation: 0,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'No fields yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first field',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(
    BuildContext context,
    FieldGroup group,
    bool isLastGroup,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        // Group Header
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 16,
            top: 24,
            bottom: 8,
          ),
          child: Row(
            children: [
              Icon(
                group.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 12),
              Text(
                group.title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        // Field forms
        ...group.fields.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: _buildFormField(context, group, entry.value, entry.key),
          ),
        ),

        // Bottom spacing unless it's the last group
        if (!isLastGroup) SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFormField(
    BuildContext context,
    FieldGroup group,
    AccountField field,
    int index,
  ) {
    BorderRadius borderRadius;

    if (group.fields.length == 1) {
      borderRadius = BorderRadius.all(Radius.circular(16));
    } else if (index == 0) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(4),
        bottomLeft: Radius.circular(4),
      );
    } else if (index == group.fields.length - 1) {
      borderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      );
    } else {
      borderRadius = BorderRadius.zero;
    }
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: () => onDeleteField(field),
          borderRadius: borderRadius,
        );
      case AccountFieldType.password:
        return PasswordField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: () => onDeleteField(field),
          borderRadius: borderRadius,
        );
      case AccountFieldType.website:
        return WebsiteField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: () => onDeleteField(field),
          borderRadius: borderRadius,
        );
      case AccountFieldType.otp:
        return OtpField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: () => onDeleteField(field),
          borderRadius: borderRadius,
        );
      default:
        return PlainTextField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: () => onDeleteField(field),
          borderRadius: borderRadius,
        );
    }
  }
}
