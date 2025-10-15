import '../models/account_field.dart';

/// Predefined templates for different account types.
/// Each template contains a list of field definitions as maps.
/// Use these to create AccountField instances by parsing the maps.
const Map<String, List<Map<String, dynamic>>> accountTemplates = {
  'Login': [
    {'label': 'Credential', 'type': 'credential', 'order': 1},
    {'label': 'Website', 'type': 'website', 'order': 2},
  ],
  'Credit Card': [
    {'label': 'Card Number', 'type': 'text', 'order': 1},
    {'label': 'Expiration Date', 'type': 'text', 'order': 2},
    {'label': 'CVV', 'type': 'text', 'order': 3},
    {'label': 'Name on Card', 'type': 'text', 'order': 4},
  ],
  'Address': [
    {'label': 'Street Address', 'type': 'text', 'order': 1},
    {'label': 'City', 'type': 'text', 'order': 2},
    {'label': 'State/Province', 'type': 'text', 'order': 3},
    {'label': 'ZIP/Postal Code', 'type': 'text', 'order': 4},
    {'label': 'Country', 'type': 'text', 'order': 5},
  ],
  'Website': [
    {'label': 'URL', 'type': 'website', 'order': 1},
    {'label': 'Username', 'type': 'credential', 'order': 2},
    {'label': 'Password', 'type': 'password', 'order': 3},
  ],
  'Note': [
    {'label': 'Content', 'type': 'text', 'order': 1},
  ],
};

/// Helper function to create an AccountField from a template map.
AccountField createFieldFromTemplate(
  Map<String, dynamic> template,
  String accountId,
) {
  return AccountField(
    accountId: accountId,
    label: template['label'] as String,
    type: AccountFieldType.fromString(template['type'] as String),
    order: template['order'] as int,
  );
}

/// Helper function to get template fields for a given template name.
List<AccountField> getTemplateFields(String templateName, String accountId) {
  final template = accountTemplates[templateName];
  if (template == null) return [];
  return template
      .map((fieldMap) => createFieldFromTemplate(fieldMap, accountId))
      .toList();
}
