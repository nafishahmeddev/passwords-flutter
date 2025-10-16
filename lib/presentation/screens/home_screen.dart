import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/account_provider.dart';
import '../../data/models/account_field.dart';
import '../../data/templates/account_templates.dart';
import 'qr_scanner_screen/qr_scanner_screen.dart';
import 'account_details_screen/account_detail_screen.dart';
import 'account_form_screen/account_form_screen.dart';
import 'account_list_screen/account_list_screen.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // List of screens/pages for the bottom navigation
  final List<Widget> _screens = [
    AccountListScreenCard(), // Using the new card-based account list
    PasswordGeneratorScreen(),
    SettingsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(), // Disable swiping
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.password_outlined),
            selectedIcon: Icon(Icons.password),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Show the "Add Account" options
                _showAddAccountOptions(context);
              },
              child: Icon(Icons.add),
              tooltip: 'Add Account',
            )
          : null,
    );
  }

  void _showAddAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Add New Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text('Create New Account'),
                  subtitle: Text('Start with a blank account'),
                  onTap: () async {
                    Navigator.pop(context);

                    // Import necessary classes
                    final provider = Provider.of<AccountProvider>(
                      context,
                      listen: false,
                    );

                    // Get template fields for the selected type
                    List<AccountField> templateFields = getTemplateFields(
                      "Login",
                      'temp',
                    );

                    // Navigate to create new account with template fields
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountFormScreen(
                          repository: provider.repository,
                          isCreateMode: true,
                          templateFields: templateFields,
                        ),
                      ),
                    );

                    // If account was successfully created, navigate to its detail screen
                    if (result == true) {
                      // Reload accounts to get the newly created account
                      await provider.loadAccounts();

                      // Find the newly created account
                      if (provider.state == AccountState.loaded &&
                          provider.accounts.isNotEmpty) {
                        final newestAccount = provider.accounts.reduce(
                          (a, b) => a.createdAt > b.createdAt ? a : b,
                        );

                        // Navigate to the detail screen of the new account
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountDetailScreen(
                                account: newestAccount,
                                repository: provider.repository,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text('Scan QR Code'),
                  subtitle: Text('Import account from QR code'),
                  onTap: () async {
                    Navigator.pop(context);

                    // Navigate to QR scanner
                    final scannedData = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QrScannerScreen()),
                    );

                    if (scannedData != null &&
                        scannedData is String &&
                        scannedData.isNotEmpty) {
                      // Process the QR code data and create an account based on it
                      // Here we could parse QR code data for specific formats like OTP
                      // For now, just show a dialog with the scanned data
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('QR Code Scanned'),
                          content: Text(
                            'Successfully scanned QR code data. Would you like to create an account with this data?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Process and create account with QR data
                                // This would typically involve parsing the QR data and
                                // navigating to the AccountFormScreen with pre-populated fields
                              },
                              child: Text('Create Account'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
