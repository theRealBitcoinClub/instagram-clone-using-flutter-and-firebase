// Lightweight topic model for memory caching - put this outside TopicService class
class MemoModelTopicLight {
  final String id;
  final int count;

  MemoModelTopicLight({required this.id, required this.count});

  factory MemoModelTopicLight.fromJson(Map<String, dynamic> json) {
    return MemoModelTopicLight(id: json['id'] ?? '', count: json['count'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'count': count};
  }
}
