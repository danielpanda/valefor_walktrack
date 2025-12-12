import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/workout_model.dart';
import '../services/storage_service.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = '/history';

  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box<Workout> _workoutBox;

  @override
  void initState() {
    super.initState();
    _workoutBox = StorageService.getWorkoutBox();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Olahraga'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportToCSV();
              } else if (value == 'clear') {
                _showClearConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 12),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _workoutBox.listenable(),
        builder: (context, Box<Workout> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat olahraga',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai tracking untuk mencatat aktivitas Anda',
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          final workouts = box.values.toList().cast<Workout>();
          workouts.sort((a, b) => b.date.compareTo(a.date));

          // Group workouts by date
          final groupedWorkouts = <String, List<Workout>>{};
          for (var workout in workouts) {
            final dateKey = DateFormat('yyyy-MM-dd').format(workout.date);
            groupedWorkouts.putIfAbsent(dateKey, () => []).add(workout);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedWorkouts.length,
            itemBuilder: (context, groupIndex) {
              final dateKey = groupedWorkouts.keys.toList()[groupIndex];
              final dayWorkouts = groupedWorkouts[dateKey]!;
              final date = DateTime.parse(dateKey);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isYesterday = DateUtils.isSameDay(
                date,
                DateTime.now().subtract(const Duration(days: 1)),
              );

              String dateLabel;
              if (isToday) {
                dateLabel = 'Hari Ini';
              } else if (isYesterday) {
                dateLabel = 'Kemarin';
              } else {
                dateLabel = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...dayWorkouts.map((workout) => _buildWorkoutCard(
                        workout,
                        colorScheme,
                        workouts.indexOf(workout),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkoutCard(
    Workout workout,
    ColorScheme colorScheme,
    int index,
  ) {
    final timeFormatted = DateFormat('HH:mm').format(workout.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openWorkoutDetail(workout, index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Activity Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: workout.activityType == ActivityType.running
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workout.activityIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              workout.activityName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timeFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${workout.distanceKm.toStringAsFixed(2)} km • ${workout.formattedDuration}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    Icons.local_fire_department,
                    '${workout.caloriesBurned.toStringAsFixed(0)}',
                    'kcal',
                    Colors.orange,
                  ),
                  _buildMiniStat(
                    Icons.speed,
                    '${workout.avgSpeedKmh.toStringAsFixed(1)}',
                    'km/h',
                    Colors.blue,
                  ),
                  _buildMiniStat(
                    Icons.av_timer,
                    workout.pace,
                    '/km',
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String unit, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          ' $unit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _openWorkoutDetail(Workout workout, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          workout: workout,
          workoutIndex: index,
        ),
      ),
    );
  }

  void _exportToCSV() {
    final workouts = _workoutBox.values.toList();

    if (workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk di-export'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
      'Tanggal,Waktu,Tipe Aktivitas,Jarak (km),Durasi (detik),Kalori (kcal),Kecepatan Rata-rata (km/h),Pace (/km)',
    );

    for (var w in workouts) {
      csvBuffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(w.date)},'
        '${DateFormat('HH:mm:ss').format(w.date)},'
        '${w.activityName},'
        '${w.distanceKm.toStringAsFixed(2)},'
        '${w.durationSeconds},'
        '${w.caloriesBurned.toStringAsFixed(0)},'
        '${w.avgSpeedKmh.toStringAsFixed(2)},'
        '${w.pace}',
      );
    }

    final csvData = csvBuffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 12),
                    Text(
                      'Data CSV',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${workouts.length} workout records',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        csvData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Salin data di atas untuk menyimpan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Semua Data?'),
          ],
        ),
        content: const Text(
          'Semua riwayat olahraga akan dihapus secara permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.deleteAllWorkouts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua data berhasil dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
