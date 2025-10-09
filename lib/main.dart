import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/services/db_helper.dart';
import 'data/repositories/account_repository.dart';
import 'business/cubit/account_cubit.dart';
import 'presentation/screens/account_list_screen.dart';

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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: AccountListScreen(),
      ),
    );
  }
}
