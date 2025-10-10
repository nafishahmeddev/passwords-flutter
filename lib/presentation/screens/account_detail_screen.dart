// lib/presentation/screens/account_detail_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import 'account_form_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;
  final AccountRepository repository;

  const AccountDetailScreen({
    super.key,
    required this.account,
    required this.repository,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  Future<List<AccountField>>? _fieldsFuture;
  Account? _currentAccount;

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
    _loadFields();
  }

  void _loadFields() {
    setState(() {
      _fieldsFuture = widget.repository.getFields(_currentAccount!.id);
    });
  }

  Future<void> _loadAccount() async {
    try {
      final accounts = await widget.repository.getAccounts();
      final updatedAccount = accounts.firstWhere(
        (acc) => acc.id == _currentAccount!.id,
      );
      setState(() {
        _currentAccount = updatedAccount;
      });
    } catch (e) {
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAccount?.name ?? widget.account.name),
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
                    accountId: _currentAccount!.id,
                    isCreateMode: false,
                  ),
                ),
              );
              // Data will refresh automatically via event system
              if (result == true) {
                await _loadAccount();
                _loadFields();
              }
            },
          ),
          PopupMenuButton(
            onSelected: (value) => _handleMenuSelection(value),
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
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
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
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
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
                Text(_currentAccount?.name ?? widget.account.name),
              ],
            ),
          ),
          SizedBox(height: 2),
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
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
                Text(_currentAccount?.note ?? widget.account.note ?? 'No note'),
              ],
            ),
          ),

          FutureBuilder<List<AccountField>>(
            future: _fieldsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error loading fields: ${snapshot.error}');
              }

              final fields = snapshot.data ?? [];
              if (fields.isEmpty) {
                return Column(
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
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final meta = fields[index];
                  return _buildFieldTile(meta);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile(AccountField field) {
    if (field.type == AccountFieldType.credential) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
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
              widget.repository.deleteAccount(_currentAccount!.id);
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
