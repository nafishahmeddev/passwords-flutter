import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/account_field.dart';
import '../qr_scanner_screen.dart';

class OtpField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;
  final BorderRadius? borderRadius;

  const OtpField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
    this.borderRadius,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late TextEditingController _secretController;
  late TextEditingController _issuerController;
  late TextEditingController _accountNameController;
  late TextEditingController _periodController;
  late TextEditingController _counterController;
  late TextEditingController _digitsController;
  Timer? _debounceTimer;
  String _selectedType = 'totp';
  String _selectedAlgorithm = 'SHA1';

  @override
  void initState() {
    super.initState();
    _secretController = TextEditingController(
      text: widget.field.getMetadata('secret'),
    );
    _issuerController = TextEditingController(
      text: widget.field.getMetadata('issuer'),
    );
    _accountNameController = TextEditingController(
      text: widget.field.getMetadata('account_name'),
    );
    _periodController = TextEditingController(
      text: widget.field.getMetadata('period', '30'),
    );
    _counterController = TextEditingController(
      text: widget.field.getMetadata('counter', '0'),
    );
    _digitsController = TextEditingController(
      text: widget.field.getMetadata('digits', '6'),
    );
    _selectedType = widget.field.getMetadata('type', 'totp');
    _selectedAlgorithm = widget.field.getMetadata('algorithm', 'SHA1');
  }

  @override
  void dispose() {
    _secretController.dispose();
    _issuerController.dispose();
    _accountNameController.dispose();
    _periodController.dispose();
    _counterController.dispose();
    _digitsController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.field.setMetadataMap({
        'secret': _secretController.text,
        'issuer': _issuerController.text,
        'account_name': _accountNameController.text,
        'period': _periodController.text,
        'counter': _counterController.text,
        'digits': _digitsController.text,
        'type': _selectedType,
        'algorithm': _selectedAlgorithm,
      });

      widget.onChange(widget.field);
    });
  }

  Future<void> _scanQrCode() async {
    try {
      // Launch QR scanner
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => QrScannerScreen()),
      );

      if (result != null && result.isNotEmpty) {
        _parseOtpAuthUrl(result);
      }
    } catch (e) {
      // Fallback to manual input if camera fails
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _QrCodeInputDialog(),
      );

      if (result != null && result.isNotEmpty) {
        _parseOtpAuthUrl(result);
      }
    }
  }

  Future<void> _showManualEntry() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _QrCodeInputDialog(),
    );

    if (result != null && result.isNotEmpty) {
      _parseOtpAuthUrl(result);
    }
  }

  void _parseOtpAuthUrl(String otpAuthUrl) {
    try {
      final uri = Uri.parse(otpAuthUrl);

      if (uri.scheme == 'otpauth') {
        final type = uri.host; // totp or hotp
        final pathSegments = uri.pathSegments;

        if (pathSegments.isNotEmpty) {
          final label = Uri.decodeComponent(pathSegments.first);
          final labelParts = label.split(':');

          String issuer = '';
          String accountName = '';

          if (labelParts.length == 2) {
            issuer = labelParts[0];
            accountName = labelParts[1];
          } else {
            accountName = label;
          }

          final queryParams = uri.queryParameters;

          setState(() {
            _selectedType = type.toLowerCase();
            _secretController.text = queryParams['secret'] ?? '';
            _issuerController.text = issuer.isNotEmpty
                ? issuer
                : queryParams['issuer'] ?? '';
            _accountNameController.text = accountName;
            _periodController.text = queryParams['period'] ?? '30';
            _counterController.text = queryParams['counter'] ?? '0';
            _digitsController.text = queryParams['digits'] ?? '6';
            _selectedAlgorithm = queryParams['algorithm'] ?? 'SHA1';
          });

          _onFieldChanged();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP Auth URL format'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(0),
      shape: widget.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: widget.borderRadius!)
          : null,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, label, and delete action
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.indigo.shade700,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.field.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // QR Code scan and manual entry buttons
              Row(
                children: [
                  // Only show QR scanner button on mobile platforms
                  if (Platform.isAndroid || Platform.isIOS) ...[
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _scanQrCode,
                        icon: Icon(Icons.qr_code_scanner),
                        label: Text('Scan QR Code'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showManualEntry,
                      icon: Icon(Icons.edit, size: 18),
                      label: Text(
                        Platform.isAndroid || Platform.isIOS
                            ? 'Manual'
                            : 'Enter OTP Data',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Type selection
              Text(
                'Type',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('TOTP'),
                      subtitle: Text('Time-based'),
                      value: 'totp',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                        _onFieldChanged();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('HOTP'),
                      subtitle: Text('Counter-based'),
                      value: 'hotp',
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                        _onFieldChanged();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Secret field
              Text(
                'Secret Key',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _secretController,
                  decoration: InputDecoration(
                    hintText: 'Enter secret key',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              SizedBox(height: 16),

              // Issuer and Account Name fields
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issuer',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _issuerController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Google',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _accountNameController,
                            decoration: InputDecoration(
                              hintText: 'Account name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Advanced settings
              ExpansionTile(
                title: Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedType == 'totp'
                                  ? 'Period (seconds)'
                                  : 'Counter',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _selectedType == 'totp'
                                    ? _periodController
                                    : _counterController,
                                decoration: InputDecoration(
                                  hintText: _selectedType == 'totp'
                                      ? '30'
                                      : '0',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge,
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digits',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _digitsController,
                                decoration: InputDecoration(
                                  hintText: '6',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: Theme.of(context).textTheme.bodyLarge,
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Algorithm selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Algorithm',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedAlgorithm,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: ['SHA1', 'SHA256', 'SHA512'].map((algorithm) {
                          return DropdownMenuItem(
                            value: algorithm,
                            child: Text(algorithm),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAlgorithm = value!;
                          });
                          _onFieldChanged();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodeInputDialog extends StatefulWidget {
  @override
  _QrCodeInputDialogState createState() => _QrCodeInputDialogState();
}

class _QrCodeInputDialogState extends State<_QrCodeInputDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.qr_code_scanner),
          SizedBox(width: 8),
          Text('Enter OTP Auth URL'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste the otpauth:// URL from the QR code or manual entry:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'otpauth://totp/Example:user@example.com?secret=...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            maxLines: 4,
            minLines: 2,
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Example format:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('Parse URL'),
        ),
      ],
    );
  }
}
