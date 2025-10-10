import 'dart:async';
import 'account_event.dart';

class AccountEventBus {
  static final AccountEventBus _instance = AccountEventBus._internal();
  factory AccountEventBus() => _instance;
  AccountEventBus._internal();

  final StreamController<AccountEvent> _eventController =
      StreamController<AccountEvent>.broadcast();

  Stream<AccountEvent> get events => _eventController.stream;

  void publish(AccountEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}