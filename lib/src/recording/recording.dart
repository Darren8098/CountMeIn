class Recording {
  final String id;
  final String filePath;
  final String trackId;
  final String trackName;
  final DateTime recordedAt;

  Recording({
    required this.id,
    required this.filePath,
    required this.trackId,
    required this.trackName,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'trackId': trackId,
        'trackName': trackName,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'],
        filePath: json['filePath'],
        trackId: json['trackId'],
        trackName: json['trackName'],
        recordedAt: DateTime.parse(json['recordedAt']),
      );
}
