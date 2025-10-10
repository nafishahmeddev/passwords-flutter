// lib/presentation/screens/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import '../../business/providers/account_detail_provider.dart';
import 'account_form_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;
  final AccountRepository repository;

  const AccountDetailScreen({
    super.key,
    required this.account,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AccountDetailProvider(repository: repository, accountId: account.id)
            ..loadFields(),
      child: _AccountDetailScreenContent(
        account: account,
        repository: repository,
      ),
    );
  }
}

class _AccountDetailScreenContent extends StatefulWidget {
  final Account account;
  final AccountRepository repository;

  const _AccountDetailScreenContent({
    required this.account,
    required this.repository,
  });

  @override
  State<_AccountDetailScreenContent> createState() =>
      _AccountDetailScreenContentState();
}

class _AccountDetailScreenContentState
    extends State<_AccountDetailScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccountDetailProvider>(
      builder: (context, provider, child) {
        final account = provider.account ?? widget.account;

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  // Navigate to edit screen and refresh when returning
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountFormScreen(
                        repository: widget.repository,
                        accountId: account.id,
                        isCreateMode: false,
                      ),
                    ),
                  );
                  // Data will refresh automatically via event system
                  if (result == true) {
                    provider.loadFields();
                  }
                },
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Text(
                  "ACCOUNT",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.05,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        letterSpacing: 1.05,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(account.name),
                  ],
                ),
              ),
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Note",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        letterSpacing: 1.05,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(account.note ?? 'No note'),
                  ],
                ),
              ),

              if (provider.isLoading)
                Center(child: CircularProgressIndicator())
              else if (provider.hasError)
                Center(
                  child: Text(provider.errorMessage ?? 'An error occurred'),
                )
              else if (provider.fields.isEmpty)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No fields available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the edit button to add some fields',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: provider.fields.length,
                  itemBuilder: (context, index) {
                    final field = provider.fields[index];
                    return _buildFieldTile(field);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldTile(AccountField field) {
    if (field.type == AccountFieldType.credential) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: Text(
                field.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 1.05,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 14,
              ),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Username/Email",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      letterSpacing: 1.05,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(field.getMetadata("username")),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 14,
              ),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      letterSpacing: 1.05,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(field.getMetadata("password")),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
      margin: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              letterSpacing: 1.05,
            ),
          ),
          SizedBox(height: 4),
          Text(field.getMetadata("value")),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    if (value == 'delete') {
      _confirmAndDeleteAccount();
    }
  }

  void _confirmAndDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AccountDetailProvider>(
                context,
                listen: false,
              ).deleteField(widget.account.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
