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
    Key? key,
    required this.account,
    required this.repository,
  }) : super(key: key);

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
      _fieldsFuture = widget.repository.getFields(_currentAccount!.id!);
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
                    accountId: _currentAccount!.id!,
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
        ],
      ),
      body: FutureBuilder<List<AccountField>>(
        future: _fieldsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading fields: ${snapshot.error}'),
            );
          }

          final metas = snapshot.data ?? [];
          if (metas.isEmpty) {
            return Center(
              child: Column(
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
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: metas.length,
            itemBuilder: (context, index) {
              final meta = metas[index];
              return _buildFieldTile(meta);
            },
          );
        },
      ),
    );
  }

  Widget _buildFieldTile(AccountField field) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(field.label, style: TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}
