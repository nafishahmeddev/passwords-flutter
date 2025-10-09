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
                return ListTile(
                  title: Text(account.name),
                  subtitle: Text(account.note ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context.read<AccountCubit>().deleteAccount(account.id!);
                    },
                  ),
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
