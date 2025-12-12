import '../models/workout_model.dart';

/// Kalkulator pembakaran kalori berdasarkan MET (Metabolic Equivalent of Task)
///
/// MET Values:
/// - Walking (3.5 mph / 5.6 km/h) = 4.3 MET
/// - Running (5 mph / 8 km/h) = 8.3 MET
/// - Running (6 mph / 9.7 km/h) = 9.8 MET
/// - Running (7 mph / 11.3 km/h) = 11.0 MET
///
/// Formula: Calories = MET × weight (kg) × duration (hours)

class CalorieCalculator {
  /// Menghitung MET berdasarkan kecepatan (km/h)
  static double getMETFromSpeed(double speedKmh) {
    if (speedKmh < 4.0) {
      // Walking lambat (< 4 km/h)
      return 2.5;
    } else if (speedKmh < 5.5) {
      // Walking normal (4-5.5 km/h)
      return 3.5;
    } else if (speedKmh < 6.5) {
      // Walking cepat (5.5-6.5 km/h)
      return 4.3;
    } else if (speedKmh < 8.0) {
      // Jogging ringan (6.5-8 km/h)
      return 6.0;
    } else if (speedKmh < 9.5) {
      // Running (8-9.5 km/h)
      return 8.3;
    } else if (speedKmh < 11.0) {
      // Running cepat (9.5-11 km/h)
      return 9.8;
    } else if (speedKmh < 13.0) {
      // Running sangat cepat (11-13 km/h)
      return 11.0;
    } else {
      // Sprint (> 13 km/h)
      return 12.8;
    }
  }

  /// Mendeteksi tipe aktivitas berdasarkan kecepatan rata-rata
  static ActivityType detectActivityType(double avgSpeedKmh) {
    return avgSpeedKmh >= 6.5 ? ActivityType.running : ActivityType.walking;
  }

  /// Menghitung kalori yang terbakar
  ///
  /// [distanceKm] - Jarak tempuh dalam kilometer
  /// [durationSeconds] - Durasi dalam detik
  /// [weightKg] - Berat badan dalam kilogram (default: 70 kg)
  static double calculateCalories({
    required double distanceKm,
    required int durationSeconds,
    double weightKg = 70.0,
  }) {
    if (durationSeconds <= 0 || distanceKm <= 0) {
      return 0.0;
    }

    // Hitung kecepatan rata-rata dalam km/h
    double durationHours = durationSeconds / 3600.0;
    double avgSpeedKmh = distanceKm / durationHours;

    // Dapatkan MET berdasarkan kecepatan
    double met = getMETFromSpeed(avgSpeedKmh);

    // Hitung kalori: MET × weight (kg) × duration (hours)
    double calories = met * weightKg * durationHours;

    return calories;
  }

  /// Menghitung kalori secara real-time berdasarkan kecepatan saat ini
  static double calculateRealTimeCalories({
    required double currentSpeedKmh,
    required int elapsedSeconds,
    double weightKg = 70.0,
  }) {
    if (elapsedSeconds <= 0) {
      return 0.0;
    }

    double met = getMETFromSpeed(currentSpeedKmh);
    double durationHours = elapsedSeconds / 3600.0;

    return met * weightKg * durationHours;
  }

  /// Format durasi menjadi string yang mudah dibaca (HH:MM:SS)
  static String formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Menghitung pace (menit per kilometer)
  static String calculatePace(double distanceKm, int durationSeconds) {
    if (distanceKm <= 0) {
      return '--:--';
    }

    double paceSeconds = durationSeconds / distanceKm;
    int paceMinutes = paceSeconds ~/ 60;
    int paceRemainingSeconds = (paceSeconds % 60).round();

    return '${paceMinutes.toString().padLeft(2, '0')}:'
        '${paceRemainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Menghitung kecepatan rata-rata dalam km/h
  static double calculateAverageSpeed(double distanceKm, int durationSeconds) {
    if (durationSeconds <= 0) {
      return 0.0;
    }
    return distanceKm / (durationSeconds / 3600.0);
  }

  /// Mendapatkan nama aktivitas dalam bahasa Indonesia
  static String getActivityName(ActivityType type) {
    return type == ActivityType.running ? 'Lari' : 'Jalan Kaki';
  }

  /// Mendapatkan ikon aktivitas
  static String getActivityIcon(ActivityType type) {
    return type == ActivityType.running ? '🏃' : '🚶';
  }
}
