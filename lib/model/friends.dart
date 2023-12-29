class Friend {
  final String id;
  final bool accepted;

  Friend({required this.id, this.accepted = false});

  factory Friend.fromJson(Map<String, dynamic> data) {
    return Friend(
      id: data['id'] ?? '',
      accepted: data['accepted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accepted': accepted,
    };
  }
}
