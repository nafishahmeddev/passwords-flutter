class Account {
  int? id;
  String name;
  String? description;
  String? note;
  String? logoUrl;
  String? logoFile;
  String? logoIcon;
  int createdAt;
  int updatedAt;

  Account({
    this.id,
    required this.name,
    this.description,
    this.note,
    this.logoUrl,
    this.logoFile,
    this.logoIcon,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'note': note,
    'logoUrl': logoUrl,
    'logoFile': logoFile,
    'logoIcon': logoIcon,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    note: map['note'],
    logoUrl: map['logoUrl'],
    logoFile: map['logoFile'],
    logoIcon: map['logoIcon'],
    createdAt: map['createdAt'],
    updatedAt: map['updatedAt'],
  );

  Account copyWith({
    int? id,
    String? name,
    String? description,
    String? note,
    String? logoUrl,
    String? logoFile,
    String? logoIcon,
    int? createdAt,
    int? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      note: note ?? this.note,
      logoUrl: logoUrl ?? this.logoUrl,
      logoFile: logoFile ?? this.logoFile,
      logoIcon: logoIcon ?? this.logoIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
