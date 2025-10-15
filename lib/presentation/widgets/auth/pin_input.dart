import 'package:flutter/material.dart';

class PinInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final int pinLength;

  const PinInput({Key? key, required this.onCompleted, this.pinLength = 4})
    : super(key: key);

  @override
  PinInputState createState() => PinInputState();
}

class PinInputState extends State<PinInput> {
  late String _pin;
  late List<String> _pinDigits;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _resetPin();
  }

  void _resetPin() {
    _pin = '';
    _pinDigits = List.filled(widget.pinLength, '');
    _error = false;
  }

  void _addDigit(String digit) {
    if (_pin.length < widget.pinLength) {
      setState(() {
        _pin = _pin + digit;
        _pinDigits[_pin.length - 1] = digit;
        _error = false;
      });

      if (_pin.length == widget.pinLength) {
        widget.onCompleted(_pin);
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pinDigits[_pin.length - 1] = '';
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void setError() {
    setState(() {
      _error = true;
      _pin = '';
      _pinDigits = List.filled(widget.pinLength, '');
    });
  }

  // Public method to reset the PIN input
  void resetPin() {
    setState(() {
      _resetPin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.pinLength,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pinDigits[index].isNotEmpty
                      ? _error
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ),
          ),
        ),

        // Error message
        if (_error)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Incorrect PIN. Please try again.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Pin keypad
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                '1',
                '2',
                '3',
              ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                '4',
                '5',
                '6',
              ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                '7',
                '8',
                '9',
              ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 80), // Spacer
                _buildKeypadButton('0'),
                Container(
                  width: 80,
                  height: 80,
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: _removeDigit,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Container(
      width: 80,
      height: 80,
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: () => _addDigit(digit),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}
