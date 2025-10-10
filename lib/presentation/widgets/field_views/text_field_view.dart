import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class TextFieldView extends StatefulWidget {
  final AccountField field;
  const TextFieldView({super.key, required this.field});
  @override
  State<TextFieldView> createState() => _TextFieldViewState();
}

class _TextFieldViewState extends State<TextFieldView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
                    field.getMetadata("value"),
                    style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // ClipboardManager.setText(field.getMetadata("username"));
                    Clipboard.setData(
                      ClipboardData(text: field.getMetadata("value")),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Value copied to clipboard')),
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
