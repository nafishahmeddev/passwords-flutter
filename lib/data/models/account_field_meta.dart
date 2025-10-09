class CredentialFieldMeta {
  String login;
  String password;

  CredentialFieldMeta({required this.login, required this.password});

  Map<String, dynamic> toMap() => {'login': login, 'password': password};

  factory CredentialFieldMeta.fromMap(Map<String, dynamic> map) =>
      CredentialFieldMeta(login: map['login'], password: map['password']);
}

class PasswordFieldMeta {
  String login;
  String value;

  PasswordFieldMeta({required this.login, required this.value});

  Map<String, dynamic> toMap() => {'login': login, 'value': value};

  factory PasswordFieldMeta.fromMap(Map<String, dynamic> map) =>
      PasswordFieldMeta(login: map['login'], value: map['value']);
}

class TextFieldMeta {
  String value;

  TextFieldMeta({required this.value});

  Map<String, dynamic> toMap() => {'value': value};

  factory TextFieldMeta.fromMap(Map<String, dynamic> map) =>
      TextFieldMeta(value: map['value']);
}

class WebsiteFieldMeta {
  String value;

  WebsiteFieldMeta({required this.value});

  Map<String, dynamic> toMap() => {'value': value};

  factory WebsiteFieldMeta.fromMap(Map<String, dynamic> map) =>
      WebsiteFieldMeta(value: map['value']);
}
