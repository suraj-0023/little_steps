class ExifData {
  const ExifData({
    this.takenAt,
    this.latitude,
    this.longitude,
    this.cameraMake,
    this.cameraModel,
  });

  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  final String? cameraMake;
  final String? cameraModel;

  bool get hasLocation => latitude != null && longitude != null;

  factory ExifData.fromMap(Map<String, dynamic> map) => ExifData(
        takenAt: map['takenAt'] != null
            ? DateTime.tryParse(map['takenAt'] as String)
            : null,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        cameraMake: map['cameraMake'] as String?,
        cameraModel: map['cameraModel'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (cameraMake != null) 'cameraMake': cameraMake,
        if (cameraModel != null) 'cameraModel': cameraModel,
      };
}
