import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/workout_model.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../utils/calorie_calculator.dart';

class TrackingScreen extends StatefulWidget {
  static const routeName = '/tracking';

  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  final List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  double _currentSpeedKmh = 0.0;
  double _caloriesBurned = 0.0;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  final MapController _mapController = MapController();

  bool _isPaused = false;
  bool _isLoading = true;
  bool _hasLocationPermission = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeTracking();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeTracking() async {
    _hasLocationPermission = await LocationService.checkAndRequestPermission();

    if (!_hasLocationPermission) {
      setState(() => _isLoading = false);
      _showPermissionDialog();
      return;
    }

    // Get initial position
    final initialPosition = await LocationService.getCurrentLatLng();
    if (initialPosition != null && mounted) {
      setState(() {
        _routePoints.add(initialPosition);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }

    _startTracking();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Izin Lokasi Diperlukan'),
          ],
        ),
        content: const Text(
          'Aplikasi memerlukan akses lokasi untuk melacak rute perjalanan Anda. '
          'Silakan aktifkan izin lokasi di pengaturan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _startTracking() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isPaused) {
        _updateCalories();
        setState(() {});
      }
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isPaused) return;

      final newPoint = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentSpeedKmh = (position.speed * 3.6).clamp(0.0, double.infinity);

        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;
          final distance = LocationService.calculateDistance(lastPoint, newPoint);

          if (distance > 0.001) {
            // More than 1 meter
            _totalDistance += distance;
            _routePoints.add(newPoint);
          }
        } else {
          _routePoints.add(newPoint);
        }
      });

      // Center map on current position
      try {
        _mapController.move(newPoint, 17);
      } catch (_) {}
    });
  }

  void _updateCalories() {
    final userWeight = StorageService.getUserWeight();
    _caloriesBurned = CalorieCalculator.calculateCalories(
      distanceKm: _totalDistance,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      weightKg: userWeight,
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopwatch.stop();
        _pulseController.stop();
      } else {
        _stopwatch.start();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _stopTracking() async {
    _stopwatch.stop();
    _timer?.cancel();
    _positionSubscription?.cancel();

    if (_routePoints.length >= 2 && _totalDistance > 0.01) {
      final avgSpeed = CalorieCalculator.calculateAverageSpeed(
        _totalDistance,
        _stopwatch.elapsed.inSeconds,
      );
      final activityType = CalorieCalculator.detectActivityType(avgSpeed);
      final pace = CalorieCalculator.calculatePace(
        _totalDistance,
        _stopwatch.elapsed.inSeconds,
      );

      final workout = Workout(
        date: DateTime.now(),
        distanceKm: _totalDistance,
        durationSeconds: _stopwatch.elapsed.inSeconds,
        route: List<LatLng>.from(_routePoints),
        caloriesBurned: _caloriesBurned,
        activityType:
            activityType == ActivityType.running ? ActivityType.running : ActivityType.walking,
        avgSpeedKmh: avgSpeed,
        pace: pace,
      );

      await StorageService.saveWorkout(workout);

      if (mounted) {
        _showWorkoutSummary(workout);
      }
    } else {
      Navigator.pop(context);
    }
  }

  void _showWorkoutSummary(Workout workout) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(workout.activityIcon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            const Text('Workout Selesai! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(
                Icons.straighten, 'Jarak', '${workout.distanceKm.toStringAsFixed(2)} km'),
            _buildSummaryRow(Icons.timer, 'Durasi', workout.formattedDuration),
            _buildSummaryRow(Icons.local_fire_department, 'Kalori',
                '${workout.caloriesBurned.toStringAsFixed(0)} kcal'),
            _buildSummaryRow(Icons.speed, 'Kecepatan Rata-rata',
                '${workout.avgSpeedKmh.toStringAsFixed(1)} km/h'),
            _buildSummaryRow(Icons.av_timer, 'Pace', '${workout.pace} /km'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final center = _routePoints.isNotEmpty
        ? _routePoints.last
        : const LatLng(-6.2088, 106.8456); // Default Jakarta

    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : !_hasLocationPermission
              ? _buildNoPermissionState()
              : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 17,
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
                              points: _routePoints,
                              color: colorScheme.primary,
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                        // Current position marker
                        if (_routePoints.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              // Start marker
                              if (_routePoints.length > 1)
                                Marker(
                                  point: _routePoints.first,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              // Current position marker
                              Marker(
                                point: _routePoints.last,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isPaused ? 1.0 : _pulseAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withOpacity(0.4),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Top Safe Area with back button
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleButton(
                              icon: Icons.arrow_back,
                              onPressed: () => _showExitConfirmation(),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isPaused ? Colors.orange : Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPaused ? Icons.pause : Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isPaused ? 'DIJEDA' : 'MELACAK',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildCircleButton(
                              icon: Icons.my_location,
                              onPressed: () {
                                if (_routePoints.isNotEmpty) {
                                  _mapController.move(_routePoints.last, 17);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Stats Panel
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildStatsPanel(colorScheme),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Mencari lokasi Anda...'),
        ],
      ),
    );
  }

  Widget _buildNoPermissionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Izin Lokasi Diperlukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aktifkan izin lokasi untuk memulai tracking',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Timer - Large Display
              Text(
                _formatDuration(_stopwatch.elapsed),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.straighten,
                    value: _totalDistance.toStringAsFixed(2),
                    unit: 'km',
                    label: 'Jarak',
                    colorScheme: colorScheme,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    value: _caloriesBurned.toStringAsFixed(0),
                    unit: 'kcal',
                    label: 'Kalori',
                    colorScheme: colorScheme,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.speed,
                    value: _currentSpeedKmh.toStringAsFixed(1),
                    unit: 'km/h',
                    label: 'Kecepatan',
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pause/Resume Button
                  _buildControlButton(
                    icon: _isPaused ? Icons.play_arrow : Icons.pause,
                    label: _isPaused ? 'Lanjut' : 'Jeda',
                    color: Colors.orange,
                    onPressed: _togglePause,
                  ),
                  // Stop Button
                  _buildControlButton(
                    icon: Icons.stop,
                    label: 'Selesai',
                    color: Colors.red,
                    onPressed: _stopTracking,
                    isLarge: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.grey[300],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(isLarge ? 24 : 16),
              child: Icon(
                icon,
                color: Colors.white,
                size: isLarge ? 40 : 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Tracking?'),
        content: const Text(
          'Workout Anda akan disimpan jika sudah ada data perjalanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTracking();
            },
            child: const Text('Keluar & Simpan'),
          ),
        ],
      ),
    );
  }
}
