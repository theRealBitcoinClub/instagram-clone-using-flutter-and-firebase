// Lightweight tag model for memory caching - put this outside TagService class
class MemoModelTagLight {
  final String id;
  final int count;

  MemoModelTagLight({required this.id, required this.count});

  factory MemoModelTagLight.fromJson(Map<String, dynamic> json) {
    return MemoModelTagLight(id: json['id'] ?? '', count: json['count'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'count': count};
  }
}
