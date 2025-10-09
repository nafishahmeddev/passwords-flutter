import 'package:uuid/uuid.dart';

enum LogoType { file, url, icon }

class Account {
  String id;
  String name;
  String? description;
  String? note;
  LogoType? logoType;
  String? logo;
  bool isFavorite;
  int createdAt;
  int updatedAt;

  Account({
    String? id,
    required this.name,
    this.description,
    this.note,
    this.logoType,
    this.logo,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'note': note,
    'logoType': logoType?.name,
    'logo': logo,
    'isFavorite': isFavorite ? 1 : 0,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'] as String,
    name: map['name'],
    description: map['description'],
    note: map['note'],
    logoType: map['logoType'] != null
        ? LogoType.values.byName(map['logoType'])
        : null,
    logo: map['logo'],
    isFavorite: map['isFavorite'] == 1,
    createdAt: map['createdAt'],
    updatedAt: map['updatedAt'],
  );

  Account copyWith({
    Object? id,
    String? name,
    String? description,
    String? note,
    LogoType? logoType,
    String? logo,
    bool? isFavorite,
    int? createdAt,
    int? updatedAt,
  }) {
    return Account(
      id: id != null ? id as String : this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      note: note ?? this.note,
      logoType: logoType ?? this.logoType,
      logo: logo ?? this.logo,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
