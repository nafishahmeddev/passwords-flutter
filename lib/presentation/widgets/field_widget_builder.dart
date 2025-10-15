import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';
import '../../business/providers/account_form_provider.dart';
import 'field_forms/credential_field.dart';
import 'field_forms/password_field.dart';
import 'field_forms/text_field.dart';
import 'field_forms/website_field.dart';
import 'field_forms/otp_field.dart';

class FieldWidgetBuilder {
  static Widget buildFieldWidget(
    BuildContext context,
    AccountField field,
    AccountFormProvider formProvider,
    VoidCallback onDelete,
  ) {
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.password:
        return PasswordField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.website:
        return WebsiteField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.otp:
        return OtpField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
      default:
        return PlainTextField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
    }
  }
}
