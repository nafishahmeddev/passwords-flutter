import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business/cubit/account_cubit.dart';
import '../../data/templates/account_templates.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountListScreen extends StatelessWidget {
  Future<void> _showAccountTypeDialog(BuildContext context) async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Account Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: accountTemplates.keys.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedType != null) {
      // Get template fields for the selected type
      final templateFields = getTemplateFields(
        selectedType,
        0,
      ); // accountId will be set later

      // Navigate to create new account with template fields
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountFormScreen(
            repository: context.read<AccountCubit>().repository,
            isCreateMode: true,
            templateFields: templateFields,
          ),
        ),
      );
    }
  }

  void _showAccountOptions(BuildContext context, account) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Account'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountFormScreen(
                        repository: context.read<AccountCubit>().repository,
                        accountId: account.id,
                        isCreateMode: false,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Account'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showDeleteConfirmationDialog(context, account);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      context.read<AccountCubit>().deleteAccount(account.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accounts')),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is AccountLoaded) {
            if (state.accounts.isEmpty) {
              return Center(child: Text('No accounts found'));
            }
            return ListView.builder(
              itemCount: state.accounts.length,
              itemBuilder: (context, index) {
                final account = state.accounts[index];
                return GestureDetector(
                  onLongPress: () => _showAccountOptions(context, account),
                  child: ListTile(
                    title: Text(account.name),
                    subtitle: Text(account.note ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(
                            account: account,
                            repository: context.read<AccountCubit>().repository,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else if (state is AccountError) {
            return Center(child: Text(state.message));
          }
          return Center(child: Text('Press + to add account'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAccountTypeDialog(context),
      ),
    );
  }
}
