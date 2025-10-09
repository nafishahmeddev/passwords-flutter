import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business/cubit/account_cubit.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountListScreen extends StatelessWidget {
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
        onPressed: () async {
          // Navigate to create new account
          // Example of how to pass template fields:
          // final templateFields = [
          //   AccountField(label: 'Username', value: '', type: 'text'),
          //   AccountField(label: 'Password', value: '', type: 'password'),
          //   AccountField(label: 'Website', value: '', type: 'website'),
          // ];
          // (Import AccountField from '../../data/models/account_field.dart')

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountFormScreen(
                repository: context.read<AccountCubit>().repository,
                isCreateMode: true,
                // templateFields: templateFields, // Uncomment to use template fields
              ),
            ),
          );
          // Account list will refresh automatically via event system
        },
      ),
    );
  }
}
