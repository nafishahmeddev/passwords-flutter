import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({Key? key}) : super(key: key);

  @override
  _PasswordGeneratorScreenState createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generatedPassword = '';
  int _passwordLength = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSpecialChars = true;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    if (!_useUppercase && !_useLowercase && !_useNumbers && !_useSpecialChars) {
      setState(() {
        _generatedPassword = 'Select at least one character type';
      });
      return;
    }

    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String numberChars = '0123456789';
    const String specialChars = '!@#\$%^&*()-_=+[]{};:,.<>/?|~';

    String allChars = '';
    if (_useUppercase) allChars += uppercaseChars;
    if (_useLowercase) allChars += lowercaseChars;
    if (_useNumbers) allChars += numberChars;
    if (_useSpecialChars) allChars += specialChars;

    final Random random = Random.secure();
    final List<String> charList = allChars.split('');

    // Ensure at least one character from each selected type
    List<String> password = [];

    if (_useUppercase) {
      password.add(uppercaseChars[random.nextInt(uppercaseChars.length)]);
    }
    if (_useLowercase) {
      password.add(lowercaseChars[random.nextInt(lowercaseChars.length)]);
    }
    if (_useNumbers) {
      password.add(numberChars[random.nextInt(numberChars.length)]);
    }
    if (_useSpecialChars) {
      password.add(specialChars[random.nextInt(specialChars.length)]);
    }

    // Fill the rest with random characters
    while (password.length < _passwordLength) {
      password.add(charList[random.nextInt(charList.length)]);
    }

    // Shuffle to randomize positions
    password.shuffle(random);

    setState(() {
      _generatedPassword = password.join('');
    });
  }

  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty &&
        _generatedPassword != 'Select at least one character type') {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Password Generator',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generated Password Display
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generated Password',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _generatedPassword,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: _copyToClipboard,
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _generatePassword,
                        icon: Icon(Icons.refresh),
                        label: Text('Generate New Password'),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Password Options
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Options',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      SizedBox(height: 16),

                      // Password Length Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Length: $_passwordLength',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: _passwordLength > 8
                                    ? () {
                                        setState(() {
                                          _passwordLength--;
                                          _generatePassword();
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: _passwordLength < 32
                                    ? () {
                                        setState(() {
                                          _passwordLength++;
                                          _generatePassword();
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: _passwordLength.toDouble(),
                        min: 8,
                        max: 32,
                        divisions: 24,
                        label: _passwordLength.toString(),
                        onChanged: (double value) {
                          setState(() {
                            _passwordLength = value.toInt();
                            _generatePassword();
                          });
                        },
                      ),

                      Divider(),

                      // Character Types
                      CheckboxListTile(
                        title: Text('Uppercase Letters (A-Z)'),
                        value: _useUppercase,
                        onChanged: (value) {
                          setState(() {
                            _useUppercase = value!;
                            _generatePassword();
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text('Lowercase Letters (a-z)'),
                        value: _useLowercase,
                        onChanged: (value) {
                          setState(() {
                            _useLowercase = value!;
                            _generatePassword();
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text('Numbers (0-9)'),
                        value: _useNumbers,
                        onChanged: (value) {
                          setState(() {
                            _useNumbers = value!;
                            _generatePassword();
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text('Special Characters (!@#\$%^&*)'),
                        value: _useSpecialChars,
                        onChanged: (value) {
                          setState(() {
                            _useSpecialChars = value!;
                            _generatePassword();
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Password Strength Card
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Strength',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      SizedBox(height: 16),
                      _buildPasswordStrength(),
                      SizedBox(height: 8),
                      Text(
                        'Tips for strong passwords:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: 8),
                      _buildTip('Use at least 12 characters'),
                      _buildTip('Include uppercase and lowercase letters'),
                      _buildTip('Include numbers and special characters'),
                      _buildTip('Avoid personal information or common words'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    // Simple password strength calculation
    int strength = 0;

    if (_generatedPassword.length >= 12) strength++;
    if (_generatedPassword.length >= 16) strength++;
    if (_useUppercase) strength++;
    if (_useLowercase) strength++;
    if (_useNumbers) strength++;
    if (_useSpecialChars) strength++;

    String strengthText = '';
    Color strengthColor = Colors.red;
    double strengthValue = 0;

    if (strength <= 2) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
      strengthValue = 0.25;
    } else if (strength <= 4) {
      strengthText = 'Moderate';
      strengthColor = Colors.orange;
      strengthValue = 0.5;
    } else if (strength <= 5) {
      strengthText = 'Strong';
      strengthColor = Colors.green;
      strengthValue = 0.75;
    } else {
      strengthText = 'Very Strong';
      strengthColor = Theme.of(context).colorScheme.primary;
      strengthValue = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Strength:'),
            Text(
              strengthText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: strengthValue,
          color: strengthColor,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(tip, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
