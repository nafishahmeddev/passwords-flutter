import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'database/db_helper.dart';
import 'repositories/account_repository.dart';
import 'cubits/account_cubit.dart';
import 'views/account_list/account_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.init();
  final repository = AccountRepository(db);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final AccountRepository repository;

  MyApp({required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountCubit(repository: repository)..loadAccounts(),
      child: MaterialApp(
        title: 'Passwords',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AccountListScreen(),
      ),
    );
  }
}
