import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/workout_model.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final int workoutIndex;

  const WorkoutDetailScreen({
    Key? key,
    required this.workout,
    required this.workoutIndex,
  }) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final workout = widget.workout;
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(workout.date);
    final timeFormatted = DateFormat('HH:mm').format(workout.date);

    // Get center and bounds for map
    LatLng center;
    double zoom = 15;

    if (workout.route.isNotEmpty) {
      center = LocationService.getCenterPoint(workout.route) ?? workout.route.first;
    } else {
      center = const LatLng(-6.2088, 106.8456);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Map
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareWorkout(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                workout.activityName,
                style: const TextStyle(
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Map
                  workout.route.isNotEmpty
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: zoom,
                            onMapReady: () {
                              setState(() => _isMapReady = true);
                              _fitMapToBounds();
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.valefor.walktrack',
                            ),
                            // Route polyline
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: workout.route,
                                  color: colorScheme.primary,
                                  strokeWidth: 5.0,
                                ),
                              ],
                            ),
                            // Markers
                            MarkerLayer(
                              markers: [
                                // Start marker
                                Marker(
                                  point: workout.route.first,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                // End marker
                                if (workout.route.length > 1)
                                  Marker(
                                    point: workout.route.last,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.stop,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tidak ada data rute'),
                              ],
                            ),
                          ),
                        ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
                  Row(
                    children: [
                      Text(
                        workout.activityIcon,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormatted,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pukul $timeFormatted',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Stats Grid
                  _buildMainStatsGrid(workout, colorScheme),
                  const SizedBox(height: 24),

                  // Additional Stats
                  Text(
                    'Detail Statistik',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailStats(workout, colorScheme),
                  const SizedBox(height: 24),

                  // Route Info
                  if (workout.route.isNotEmpty) ...[
                    Text(
                      'Informasi Rute',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRouteInfo(workout, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitMapToBounds() {
    if (!_isMapReady || widget.workout.route.length < 2) return;

    final bounds = LocationService.getBoundingBox(widget.workout.route);
    if (bounds == null) return;

    // Add padding to bounds
    const padding = 0.002;
    final sw = LatLng(bounds['minLat']! - padding, bounds['minLng']! - padding);
    final ne = LatLng(bounds['maxLat']! + padding, bounds['maxLng']! + padding);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(sw, ne),
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {}
  }

  Widget _buildMainStatsGrid(Workout workout, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMainStatCard(
            icon: Icons.straighten,
            value: workout.distanceKm.toStringAsFixed(2),
            unit: 'km',
            label: 'Jarak',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMainStatCard(
            icon: Icons.timer,
            value: workout.formattedDuration,
            unit: '',
            label: 'Durasi',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 16,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStats(Workout workout, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailStatRow(
              Icons.local_fire_department,
              'Kalori Terbakar',
              '${workout.caloriesBurned.toStringAsFixed(0)} kcal',
              Colors.orange,
            ),
            const Divider(height: 24),
            _buildDetailStatRow(
              Icons.speed,
              'Kecepatan Rata-rata',
              '${workout.avgSpeedKmh.toStringAsFixed(1)} km/h',
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildDetailStatRow(
              Icons.av_timer,
              'Pace',
              '${workout.pace} /km',
              Colors.green,
            ),
            const Divider(height: 24),
            _buildDetailStatRow(
              Icons.category,
              'Tipe Aktivitas',
              workout.activityName,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStatRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(Workout workout, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailStatRow(
              Icons.location_on,
              'Titik Koordinat',
              '${workout.route.length} titik',
              Colors.red,
            ),
            if (workout.route.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailStatRow(
                Icons.flag,
                'Titik Mulai',
                '${workout.route.first.latitude.toStringAsFixed(5)}, ${workout.route.first.longitude.toStringAsFixed(5)}',
                Colors.green,
              ),
              if (workout.route.length > 1) ...[
                const Divider(height: 24),
                _buildDetailStatRow(
                  Icons.stop_circle,
                  'Titik Akhir',
                  '${workout.route.last.latitude.toStringAsFixed(5)}, ${workout.route.last.longitude.toStringAsFixed(5)}',
                  Colors.red,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Workout?'),
          ],
        ),
        content: const Text(
          'Data workout ini akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final box = StorageService.getWorkoutBox();
              await box.deleteAt(widget.workoutIndex);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to history
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workout berhasil dihapus'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _shareWorkout() {
    final workout = widget.workout;
    final dateFormatted = DateFormat('d MMMM yyyy, HH:mm').format(workout.date);

    final shareText = '''
🏃 ${workout.activityName} - Valefor WalkTrack

📅 $dateFormatted
📏 Jarak: ${workout.distanceKm.toStringAsFixed(2)} km
⏱️ Durasi: ${workout.formattedDuration}
🔥 Kalori: ${workout.caloriesBurned.toStringAsFixed(0)} kcal
⚡ Kecepatan: ${workout.avgSpeedKmh.toStringAsFixed(1)} km/h
🎯 Pace: ${workout.pace} /km

#ValeforWalkTrack #Fitness #Running #Walking
''';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bagikan Workout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                shareText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Salin teks di atas untuk dibagikan',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
