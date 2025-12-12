import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';

/// Helper untuk Export data ke CSV
class CsvHelper {
  /// Generate CSV content dari list workouts
  static String generateCsvContent(List<Workout> workouts) {
    final csvBuffer = StringBuffer();

    // Header
    csvBuffer.writeln(
      'Tanggal,Waktu,Tipe Aktivitas,Jarak (km),Durasi (detik),Durasi (format),Kalori (kcal),Kecepatan Rata-rata (km/h),Pace (/km),Jumlah Titik GPS',
    );

    // Data rows
    for (var w in workouts) {
      csvBuffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(w.date)},'
        '${DateFormat('HH:mm:ss').format(w.date)},'
        '${w.activityName},'
        '${w.distanceKm.toStringAsFixed(2)},'
        '${w.durationSeconds},'
        '${w.formattedDuration},'
        '${w.caloriesBurned.toStringAsFixed(0)},'
        '${w.avgSpeedKmh.toStringAsFixed(2)},'
        '${w.pace},'
        '${w.route.length}',
      );
    }

    return csvBuffer.toString();
  }

  /// Generate CSV dengan data koordinat rute
  static String generateDetailedCsvContent(Workout workout) {
    final csvBuffer = StringBuffer();

    // Workout info header
    csvBuffer.writeln('# Workout Detail Export');
    csvBuffer.writeln('# Tanggal: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(workout.date)}');
    csvBuffer.writeln('# Tipe: ${workout.activityName}');
    csvBuffer.writeln('# Jarak: ${workout.distanceKm.toStringAsFixed(2)} km');
    csvBuffer.writeln('# Durasi: ${workout.formattedDuration}');
    csvBuffer.writeln('# Kalori: ${workout.caloriesBurned.toStringAsFixed(0)} kcal');
    csvBuffer.writeln('');

    // Route data header
    csvBuffer.writeln('Index,Latitude,Longitude');

    // Route data rows
    for (var i = 0; i < workout.route.length; i++) {
      final point = workout.route[i];
      csvBuffer.writeln('$i,${point.latitude},${point.longitude}');
    }

    return csvBuffer.toString();
  }

  /// Simpan CSV ke file
  static Future<File?> saveCsvToFile(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      return await file.writeAsString(content);
    } catch (e) {
      return null;
    }
  }

  /// Generate filename dengan timestamp
  static String generateFilename({String prefix = 'walktrack_export'}) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$timestamp.csv';
  }

  /// Generate GPX content untuk kompatibilitas dengan app lain (Strava, dll)
  static String generateGpxContent(Workout workout) {
    final gpxBuffer = StringBuffer();

    gpxBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    gpxBuffer.writeln('<gpx version="1.1" creator="Valefor WalkTrack">');
    gpxBuffer.writeln('  <metadata>');
    gpxBuffer.writeln(
        '    <name>${workout.activityName} - ${DateFormat('yyyy-MM-dd').format(workout.date)}</name>');
    gpxBuffer.writeln('    <time>${workout.date.toUtc().toIso8601String()}</time>');
    gpxBuffer.writeln('  </metadata>');
    gpxBuffer.writeln('  <trk>');
    gpxBuffer.writeln('    <name>${workout.activityName}</name>');
    gpxBuffer.writeln(
        '    <type>${workout.activityType == ActivityType.running ? "running" : "walking"}</type>');
    gpxBuffer.writeln('    <trkseg>');

    for (var point in workout.route) {
      gpxBuffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}"></trkpt>');
    }

    gpxBuffer.writeln('    </trkseg>');
    gpxBuffer.writeln('  </trk>');
    gpxBuffer.writeln('</gpx>');

    return gpxBuffer.toString();
  }
}
