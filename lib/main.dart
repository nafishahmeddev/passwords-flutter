import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/db_helper.dart';
import 'data/repositories/account_repository.dart';
import 'business/providers/account_provider.dart';
import 'presentation/screens/account_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.init();
  final repository = AccountRepository(db);

  runApp(MainApp(repository: repository));
}

class MainApp extends StatelessWidget {
  final AccountRepository repository;

  const MainApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountProvider(repository: repository)..loadAccounts(),
      child: MaterialApp(
        title: 'Passwords',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          brightness: Brightness.light,
        ),
        home: AccountListScreen(),
      ),
    );
  }
}
