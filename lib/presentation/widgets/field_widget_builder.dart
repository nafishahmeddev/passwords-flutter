import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';
import '../../business/providers/account_form_provider.dart';
import 'credential_field.dart';
import 'password_field.dart';
import 'text_field.dart';
import 'website_field.dart';

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
      default:
        return PlainTextField(
          field: field,
          onChange: (f) => formProvider.updateField(f),
          onRemove: onDelete,
        );
    }
  }
}
