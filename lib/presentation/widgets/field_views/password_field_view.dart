import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class PasswordFieldView extends StatefulWidget {
  final AccountField field;
  const PasswordFieldView({super.key, required this.field});
  @override
  State<PasswordFieldView> createState() => _PasswordFieldViewState();
}

class _PasswordFieldViewState extends State<PasswordFieldView> {
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
    return Card(
      margin: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
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
                        ? field.getMetadata("value")
                        : '•' * field.getMetadata("value").length,
                    style: TextStyle(fontSize: 16, letterSpacing: 1.2),
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
                    Clipboard.setData(
                      ClipboardData(text: field.getMetadata("value")),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password copied to clipboard')),
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
    );
  }
}
