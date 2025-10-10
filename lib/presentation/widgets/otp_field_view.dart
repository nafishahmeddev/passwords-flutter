import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import '../../data/models/account_field.dart';

class OtpFieldView extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field)? onFieldUpdate;

  const OtpFieldView({super.key, required this.field, this.onFieldUpdate});

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
    final type = widget.field.getMetadata('type', 'totp');
    _generateCode();
    if (type == 'totp') {
      _startTimer();
    }
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
      final counter =
          int.tryParse(widget.field.getMetadata('counter', '0')) ?? 0;
      setState(() {
        _currentCode = _generateHOTP(secret, counter, digits);
      });
      // Increment counter for next generation
      final newCounter = counter + 1;
      widget.field.setMetadata('counter', newCounter.toString());

      // Persist the updated field to the database
      if (widget.onFieldUpdate != null) {
        widget.onFieldUpdate!(widget.field);
      }
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

  String _generateHOTP(String secret, int counter, int digits) {
    try {
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

      final code = OTP.generateHOTPCodeString(
        secret,
        counter,
        length: digits,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and label - following the standard pattern
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (type == 'totp' ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.security,
                        color: type == 'totp'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.field.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    // Type indicator
                    Text(
                      type.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // OTP code content - following the standard pattern
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Code display row
                      Row(
                        children: [
                          Icon(
                            Icons.key,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isVisible ? _currentCode : '••••••',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          // Action buttons
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                _toggleVisibility();
                                HapticFeedback.lightImpact();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  _isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                _copyCode();
                                HapticFeedback.lightImpact();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.copy,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          if (type == 'hotp')
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _generateCode();
                                  HapticFeedback.lightImpact();
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Timer for TOTP
                      if (type == 'totp') ...[
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Expires in ${_timeRemaining}s',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
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
                                backgroundColor: colorScheme.outline
                                    .withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _timeRemaining <= 5
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Account info
                      if (_issuerText != 'OTP Code') ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _issuerText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
