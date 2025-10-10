import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/account_field.dart';

class CredentialFieldView extends StatefulWidget {
  final AccountField field;

  const CredentialFieldView({super.key, required this.field});

  @override
  State<CredentialFieldView> createState() => _CredentialFieldViewState();
}

class _CredentialFieldViewState extends State<CredentialFieldView> {
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 3,
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
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
            ),

            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 14,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.getMetadata("username"),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // ClipboardManager.setText(field.getMetadata("username"));
                          Clipboard.setData(
                            ClipboardData(text: field.getMetadata("username")),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Username copied to clipboard'),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topRight: Radius.circular(5),
                topLeft: Radius.circular(5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 14,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isPasswordVisible
                              ? field.getMetadata("password")
                              : '••••••••••••',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _togglePasswordVisibility,
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // ClipboardManager.setText(field.getMetadata("username"));
                          Clipboard.setData(
                            ClipboardData(text: field.getMetadata("password")),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password copied to clipboard'),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
