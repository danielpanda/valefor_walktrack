import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_model.dart';

/// Service untuk mengelola penyimpanan data dengan Hive
class StorageService {
  static const String workoutBoxName = 'workouts';
  static const String settingsBoxName = 'settings';

  /// Inisialisasi Hive dan register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WorkoutAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LatLngAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ActivityTypeAdapter());
    }

    // Buka boxes
    await Hive.openBox<Workout>(workoutBoxName);
    await Hive.openBox(settingsBoxName);
  }

  /// Mendapatkan workout box
  static Box<Workout> getWorkoutBox() {
    return Hive.box<Workout>(workoutBoxName);
  }

  /// Mendapatkan settings box
  static Box getSettingsBox() {
    return Hive.box(settingsBoxName);
  }

  /// Menyimpan workout baru
  static Future<int> saveWorkout(Workout workout) async {
    final box = getWorkoutBox();
    return await box.add(workout);
  }

  /// Mendapatkan semua workout
  static List<Workout> getAllWorkouts() {
    final box = getWorkoutBox();
    return box.values.toList();
  }

  /// Mendapatkan workout berdasarkan index
  static Workout? getWorkout(int index) {
    final box = getWorkoutBox();
    if (index >= 0 && index < box.length) {
      return box.getAt(index);
    }
    return null;
  }

  /// Menghapus workout
  static Future<void> deleteWorkout(int index) async {
    final box = getWorkoutBox();
    await box.deleteAt(index);
  }

  /// Menghapus semua workout
  static Future<void> deleteAllWorkouts() async {
    final box = getWorkoutBox();
    await box.clear();
  }

  /// Menyimpan setting
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = getSettingsBox();
    await box.put(key, value);
  }

  /// Mendapatkan setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = getSettingsBox();
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Mendapatkan berat badan user (default 70 kg)
  static double getUserWeight() {
    return getSetting<double>('userWeight', defaultValue: 70.0) ?? 70.0;
  }

  /// Menyimpan berat badan user
  static Future<void> setUserWeight(double weight) async {
    await saveSetting('userWeight', weight);
  }

  /// Mendapatkan statistik total
  static Map<String, dynamic> getTotalStats() {
    final workouts = getAllWorkouts();

    double totalDistance = 0;
    int totalDuration = 0;
    double totalCalories = 0;

    for (var workout in workouts) {
      totalDistance += workout.distanceKm;
      totalDuration += workout.durationSeconds;
      totalCalories += workout.caloriesBurned;
    }

    return {
      'totalWorkouts': workouts.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
    };
  }

  /// Mendapatkan statistik mingguan
  static Map<String, dynamic> getWeeklyStats() {
    final workouts = getAllWorkouts();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklyWorkouts = workouts.where((w) => w.date.isAfter(weekAgo)).toList();

    double totalDistance = 0;
    int totalDuration = 0;
    double totalCalories = 0;

    for (var workout in weeklyWorkouts) {
      totalDistance += workout.distanceKm;
      totalDuration += workout.durationSeconds;
      totalCalories += workout.caloriesBurned;
    }

    return {
      'totalWorkouts': weeklyWorkouts.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
    };
  }

  /// Menutup semua boxes
  static Future<void> close() async {
    await Hive.close();
  }
}
