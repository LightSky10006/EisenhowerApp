class Task {
  String title;
  String description; // 備註，最多400字
  int quadrant; // 0:重要且緊急, 1:重要不緊急, 2:不重要但緊急, 3:不重要不緊急
  int importance; // -5~+5
  int urgency; // -5~+5
  int? id;
  int? createdAt;
  int? updatedAt;
  
  Task(
    this.title, 
    this.quadrant, {
    this.description = '',
    this.importance = 0, 
    this.urgency = 0, 
    this.id,
    this.createdAt,
    this.updatedAt,
  })  : assert(title.length <= 72, 'Title must be 72 characters or less'),
        assert(description.length <= 400, 'Description must be 400 characters or less');

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'quadrant': quadrant,
    'importance': importance,
    'urgency': urgency,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
  
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    map['title'],
    map['quadrant'],
    description: map['description'] ?? '',
    importance: map['importance'],
    urgency: map['urgency'],
    id: map['id'],
    createdAt: map['created_at'],
    updatedAt: map['updated_at'],
  );
  
  Task copyWith({
    String? title,
    String? description,
    int? quadrant,
    int? importance,
    int? urgency,
    int? id,
    int? createdAt,
    int? updatedAt,
  }) {
    return Task(
      title ?? this.title,
      quadrant ?? this.quadrant,
      description: description ?? this.description,
      importance: importance ?? this.importance,
      urgency: urgency ?? this.urgency,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.quadrant == quadrant &&
        other.importance == importance &&
        other.urgency == urgency;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        quadrant.hashCode ^
        importance.hashCode ^
        urgency.hashCode;
  }
  
  @override
  String toString() {
    return title;
  }
}
