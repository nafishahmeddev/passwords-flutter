import 'package:flutter/material.dart';
import '../../models/account_field.dart';
import '../../repositories/account_repository.dart';
import 'fields/credential_field.dart';
import 'fields/password_field.dart';
import 'fields/text_field.dart';
import 'fields/website_field.dart';

class FieldWidgetBuilder {
  static Widget buildFieldWidget(
    BuildContext context,
    AccountField field,
    AccountRepository repository,
    VoidCallback onDelete,
  ) {
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialField(
          field: field,
          onChange: (f) => repository.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.password:
        return PasswordField(
          field: field,
          onChange: (f) => repository.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.website:
        return WebsiteField(
          field: field,
          onChange: (f) => repository.updateField(f),
          onRemove: onDelete,
        );
      default:
        return PlainTextField(
          field: field,
          onChange: (f) => repository.updateField(f),
          onRemove: onDelete,
        );
    }
  }
}
