class Note {
  int? id;
  String title;
  String content;
  int priority;
  int userId; // Thêm trường userId
  DateTime createdAt;
  DateTime modifiedAt;
  List<String>? tags;
  String? color;
  String? imagePath;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.userId, // Thêm userId vào constructor
    required this.createdAt,
    required this.modifiedAt,
    this.tags,
    this.color,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority,
      'userId': userId, // Thêm userId vào map
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags?.join(','), // Chuyển List<String> thành chuỗi
      'color': color,
      'imagePath': imagePath,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      title: map['title'],
      content: map['content'],
      priority: map['priority'] is String ? int.parse(map['priority']) : map['priority'],
      userId: map['userId'] is String ? int.parse(map['userId']) : map['userId'], // Thêm userId
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      tags: map['tags'] != null ? (map['tags'] as String).split(',') : null,
      color: map['color'],
      imagePath: map['imagePath'],
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? priority,
    int? userId, // Thêm userId vào copyWith
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    String? color,
    String? imagePath,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId, // Cập nhật userId
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, priority: $priority, userId: $userId, imagePath: $imagePath)';
  }
}