import 'package:flutter/material.dart';
import '../../models/account_field.dart';
import '../../cubits/account_edit_cubit.dart';
import 'fields/credential_field.dart';
import 'fields/password_field.dart';
import 'fields/text_field.dart';
import 'fields/website_field.dart';

class FieldWidgetBuilder {
  static Widget buildFieldWidget(
    BuildContext context,
    AccountField field,
    AccountEditCubit formCubit,
    VoidCallback onDelete,
  ) {
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialField(
          field: field,
          onChange: (f) => formCubit.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.password:
        return PasswordField(
          field: field,
          onChange: (f) => formCubit.updateField(f),
          onRemove: onDelete,
        );
      case AccountFieldType.website:
        return WebsiteField(
          field: field,
          onChange: (f) => formCubit.updateField(f),
          onRemove: onDelete,
        );
      default:
        return PlainTextField(
          field: field,
          onChange: (f) => formCubit.updateField(f),
          onRemove: onDelete,
        );
    }
  }
}
