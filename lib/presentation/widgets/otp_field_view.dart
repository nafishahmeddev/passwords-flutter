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
        algorithm: otpAlgorithm,
        interval: int.tryParse(widget.field.getMetadata('period', '30')) ?? 30,
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

  String get _issuerText {
    final issuer = widget.field.getMetadata('issuer', '');
    final accountName = widget.field.getMetadata('accountName', '');

    if (issuer.isNotEmpty && accountName.isNotEmpty) {
      return '$issuer ($accountName)';
    } else if (issuer.isNotEmpty) {
      return issuer;
    } else if (accountName.isNotEmpty) {
      return accountName;
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = widget.field.getMetadata('type', 'totp');
    final period = int.tryParse(widget.field.getMetadata('period', '30')) ?? 30;
    final issuerText = _issuerText;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field label - simple clean design with larger font
            Row(
              children: [
                Text(widget.field.label, style: theme.textTheme.titleSmall),

                if (issuerText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "($issuerText)",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8),

            // OTP code row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // For TOTP, show circular progress indicator
                if (type == 'totp' &&
                    _currentCode != 'No secret' &&
                    _currentCode != 'Invalid secret')
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(
                        begin: 0,
                        end: _timeRemaining / period,
                      ),
                      duration: const Duration(
                        milliseconds: 1000,
                      ), // Adjust duration for desired speed
                      curve: Curves.easeInOut, // Choose a suitable curve
                      builder: (context, value, child) {
                        // Circular progress indicator
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: theme.colorScheme.outline.withAlpha(
                            50,
                          ),
                        );
                      },
                    ),
                  )
                // For HOTP or error states, show regular icon
                else
                  Icon(
                    Icons.security,
                    size: 20,
                    color: type == 'totp'
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                SizedBox(width: 12),

                // OTP code - formatted for readability with increased font size
                Expanded(
                  child: Text(
                    _formatOtpCode(_currentCode),
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // Copy button (only for valid codes)
                if (_currentCode != 'No secret' &&
                    _currentCode != 'Invalid secret')
                  IconButton(
                    onPressed: () {
                      _copyCode();
                      HapticFeedback.lightImpact();
                    },
                    icon: Icon(Icons.copy_outlined, size: 18),
                    color: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(),
                  ),

                // Refresh button (only for HOTP)
                if (type == 'hotp' &&
                    _currentCode != 'No secret' &&
                    _currentCode != 'Invalid secret')
                  IconButton(
                    onPressed: () {
                      _generateCode();
                      HapticFeedback.mediumImpact();
                    },
                    icon: Icon(Icons.refresh, size: 18),
                    color: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOtpCode(String code) {
    if (code == 'No secret' || code == 'Invalid secret') {
      return code;
    }

    // Format code in pairs for better readability
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    } else if (code.length == 8) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    }
    return code;
  }
}
