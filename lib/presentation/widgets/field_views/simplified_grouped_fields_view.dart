import 'package:flutter/material.dart';
import '../../../data/models/account_field.dart';
import '../../utils/field_grouping_utils.dart';
import 'credential_field_view.dart';
import 'password_field_view.dart';
import 'text_field_view.dart';
import 'website_field_view.dart';
import 'otp_field_view.dart';
import 'package:provider/provider.dart';
import '../../../business/providers/account_detail_provider.dart';

/// A pixel-style widget that displays all field groups in a clean, native Android layout
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

        return PixelGroupSection(
          group: group,
          isLastGroup: index == sortedGroups.length - 1,
        );
      },
    );
  }
}

/// A Pixel-style group section with header and fields
class PixelGroupSection extends StatelessWidget {
  final FieldGroup group;
  final bool isLastGroup;

  const PixelGroupSection({
    super.key,
    required this.group,
    this.isLastGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        // Group Header (Pixel style)
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
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

        // Fields (Pixel style)
        ...group.fields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return _buildFieldWidget(field, index);
        }),

        // Bottom spacing unless it's the last group
        if (!isLastGroup) SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFieldWidget(AccountField field, int index) {
    BorderRadius borderRadius;
    if (group.fields.length == 1) {
      borderRadius = BorderRadius.all(Radius.circular(12));
    } else if (index == 0) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
        bottomRight: Radius.circular(4),
        bottomLeft: Radius.circular(4),
      );
    } else if (index == group.fields.length - 1) {
      borderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      );
    } else {
      borderRadius = BorderRadius.zero;
    }
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialFieldView(field: field, borderRadius: borderRadius);
      case AccountFieldType.password:
        return PasswordFieldView(field: field, borderRadius: borderRadius);
      case AccountFieldType.text:
        return TextFieldView(field: field, borderRadius: borderRadius);
      case AccountFieldType.website:
        return WebsiteFieldView(field: field, borderRadius: borderRadius);
      case AccountFieldType.otp:
        return Consumer<AccountDetailProvider>(
          builder: (context, provider, child) {
            return OtpFieldView(
              field: field,
              onFieldUpdate: (updatedField) {
                provider.updateField(updatedField);
              },
              borderRadius: borderRadius,
            );
          },
        );
    }
  }
}
