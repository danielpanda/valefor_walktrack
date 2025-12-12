import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'workout_model.g.dart';

/// Jenis aktivitas olahraga
@HiveType(typeId: 2)
enum ActivityType {
  @HiveField(0)
  walking,

  @HiveField(1)
  running,
}

/// Model untuk menyimpan data workout
@HiveType(typeId: 0)
class Workout extends HiveObject {
  /// Tanggal dan waktu workout
  @HiveField(0)
  DateTime date;

  /// Jarak tempuh dalam kilometer
  @HiveField(1)
  double distanceKm;

  /// Durasi dalam detik
  @HiveField(2)
  int durationSeconds;

  /// Daftar titik koordinat rute
  @HiveField(3)
  List<LatLng> route;

  /// Kalori yang terbakar
  @HiveField(4)
  double caloriesBurned;

  /// Jenis aktivitas (jalan/lari)
  @HiveField(5)
  ActivityType activityType;

  /// Kecepatan rata-rata dalam km/h
  @HiveField(6)
  double avgSpeedKmh;

  /// Pace dalam format menit/km
  @HiveField(7)
  String pace;

  Workout({
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.route,
    this.caloriesBurned = 0.0,
    this.activityType = ActivityType.walking,
    this.avgSpeedKmh = 0.0,
    this.pace = '--:--',
  });

  /// Mendapatkan durasi dalam format string
  String get formattedDuration {
    int hours = durationSeconds ~/ 3600;
    int minutes = (durationSeconds % 3600) ~/ 60;
    int seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Mendapatkan nama aktivitas
  String get activityName {
    return activityType == ActivityType.running ? 'Lari' : 'Jalan Kaki';
  }

  /// Mendapatkan ikon aktivitas
  String get activityIcon {
    return activityType == ActivityType.running ? '🏃' : '🚶';
  }
}

/// Adapter untuk LatLng
class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final typeId = 1;

  @override
  LatLng read(BinaryReader reader) {
    final lat = reader.readDouble();
    final lng = reader.readDouble();
    return LatLng(lat, lng);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
  }
}

/// Adapter untuk ActivityType
class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final typeId = 2;

  @override
  ActivityType read(BinaryReader reader) {
    final index = reader.readInt();
    return ActivityType.values[index];
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    writer.writeInt(obj.index);
  }
}
