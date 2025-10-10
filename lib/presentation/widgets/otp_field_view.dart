import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import '../../data/models/account_field.dart';

class OtpFieldView extends StatefulWidget {
  final AccountField field;

  const OtpFieldView({super.key, required this.field});

  @override
  State<OtpFieldView> createState() => _OtpFieldViewState();
}

class _OtpFieldViewState extends State<OtpFieldView> {
  String _currentCode = '';
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _generateCode();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateCode() {
    final secret = widget.field.getMetadata('secret', '');
    final type = widget.field.getMetadata('type', 'totp');
    final digits = int.tryParse(widget.field.getMetadata('digits', '6')) ?? 6;
    final period = int.tryParse(widget.field.getMetadata('period', '30')) ?? 30;

    if (secret.isEmpty) {
      setState(() {
        _currentCode = 'No secret';
      });
      return;
    }

    if (type == 'totp') {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeStep = now ~/ period;
      _currentCode = _generateTOTP(secret, timeStep, digits);
      _timeRemaining = period - (now % period);
    } else if (type == 'hotp') {
      // For HOTP, you'd need to store and increment a counter
      // For now, just show a placeholder
      _currentCode = 'Click to generate';
    }
  }

  String _generateTOTP(String secret, int timeStep, int digits) {
    try {
      // Use the proper OTP library for TOTP generation
      final algorithm = widget.field.getMetadata('algorithm', 'SHA1');

      Algorithm otpAlgorithm;
      switch (algorithm) {
        case 'SHA256':
          otpAlgorithm = Algorithm.SHA256;
          break;
        case 'SHA512':
          otpAlgorithm = Algorithm.SHA512;
          break;
        default:
          otpAlgorithm = Algorithm.SHA1;
      }

      final code = OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        length: digits,
        interval: int.tryParse(widget.field.getMetadata('period', '30')) ?? 30,
        algorithm: otpAlgorithm,
        isGoogle: true,
      );

      return code;
    } catch (e) {
      return 'Invalid secret';
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final type = widget.field.getMetadata('type', 'totp');
      if (type == 'totp') {
        final period =
            int.tryParse(widget.field.getMetadata('period', '30')) ?? 30;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final newTimeRemaining = period - (now % period);

        if (newTimeRemaining != _timeRemaining) {
          setState(() {
            _timeRemaining = newTimeRemaining;
          });

          if (_timeRemaining == period) {
            _generateCode();
          }
        }
      }
    });
  }

  void _copyCode() {
    if (_currentCode.isNotEmpty &&
        _currentCode != 'No secret' &&
        _currentCode != 'Invalid secret') {
      Clipboard.setData(ClipboardData(text: _currentCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP code copied to clipboard'),
          behavior: SnackBarBehavior.fixed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  String get _issuerText {
    final issuer = widget.field.getMetadata('issuer', '');
    final accountName = widget.field.getMetadata('account_name', '');

    if (issuer.isNotEmpty && accountName.isNotEmpty) {
      return '$issuer ($accountName)';
    } else if (issuer.isNotEmpty) {
      return issuer;
    } else if (accountName.isNotEmpty) {
      return accountName;
    } else {
      return 'OTP Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.field.getMetadata('type', 'totp');

    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and label
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.field.label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          _issuerText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Type badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: type == 'totp'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: type == 'totp'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Code display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _isVisible ? _currentCode : '••••••',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                onPressed: _toggleVisibility,
                                icon: Icon(
                                  _isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.all(4),
                                  minimumSize: Size(24, 24),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          if (type == 'totp') ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Expires in ${_timeRemaining}s',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value:
                                        _timeRemaining /
                                        (int.tryParse(
                                              widget.field.getMetadata(
                                                'period',
                                                '30',
                                              ),
                                            ) ??
                                            30),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _timeRemaining <= 5
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      children: [
                        IconButton(
                          onPressed: _copyCode,
                          icon: Icon(Icons.copy),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.5),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          tooltip: 'Copy code',
                        ),
                        if (type == 'hotp')
                          IconButton(
                            onPressed: _generateCode,
                            icon: Icon(Icons.refresh),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer.withOpacity(0.5),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            tooltip: 'Generate new code',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Additional info if available
              if (widget.field.getMetadata('algorithm', 'SHA1') != 'SHA1' ||
                  widget.field.getMetadata('digits', '6') != '6' ||
                  widget.field.getMetadata('period', '30') != '30') ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (widget.field.getMetadata('algorithm', 'SHA1') !=
                              'SHA1')
                            Chip(
                              label: Text(
                                widget.field.getMetadata('algorithm', 'SHA1'),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.labelSmall,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (widget.field.getMetadata('digits', '6') != '6')
                            Chip(
                              label: Text(
                                '${widget.field.getMetadata('digits', '6')} digits',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.labelSmall,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (widget.field.getMetadata('period', '30') !=
                                  '30' &&
                              type == 'totp')
                            Chip(
                              label: Text(
                                '${widget.field.getMetadata('period', '30')}s period',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.labelSmall,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
