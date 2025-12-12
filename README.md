# 🏃 Valefor WalkTrack

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.32+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

**Valefor WalkTrack** adalah aplikasi tracking aktivitas jalan kaki dan lari berbasis Flutter. Terinspirasi dari Strava, aplikasi ini membantu Anda melacak rute perjalanan, menghitung jarak tempuh, kalori yang terbakar, dan menyimpan riwayat olahraga Anda.

---

## ✨ Fitur Utama

### 🗺️ GPS Tracking Real-time

- Melacak rute perjalanan dengan titik koordinat GPS
- Peta interaktif menggunakan OpenStreetMap (gratis, tanpa API key)
- Marker animasi untuk posisi saat ini dan titik start
- Auto-center peta mengikuti posisi pengguna

### 📊 Kalkulasi Statistik Lengkap

| Metrik              | Deskripsi                               |
| ------------------- | --------------------------------------- |
| 📏 **Jarak**        | Jarak tempuh dalam kilometer            |
| ⏱️ **Durasi**       | Timer real-time dengan format HH:MM:SS  |
| 🔥 **Kalori**       | Kalori terbakar berdasarkan formula MET |
| ⚡ **Kecepatan**    | Kecepatan rata-rata dalam km/h          |
| 🎯 **Pace**         | Pace dalam format menit/km              |
| 🏃/🚶 **Aktivitas** | Auto-detect jalan kaki atau lari        |

### ⏸️ Pause & Resume

- Kontrol penuh atas tracking
- Pause saat istirahat tanpa kehilangan data
- Resume kapan saja untuk melanjutkan

### 📜 Riwayat Workout

- Daftar workout terorganisir berdasarkan tanggal
- Detail lengkap setiap sesi olahraga
- Lihat ulang rute di peta
- Hapus workout individual atau semua data

### 📤 Export Data

- Export ke format CSV
- Format GPX untuk kompatibilitas dengan aplikasi fitness lain
- Data siap untuk analisis lebih lanjut

### 🎨 UI/UX Modern

- Material Design 3
- Support Dark Mode otomatis
- Animasi smooth dan responsif
- Statistik dashboard yang informatif

---

## 🛠️ Tech Stack

| Teknologi                                               | Kegunaan                    |
| ------------------------------------------------------- | --------------------------- |
| [Flutter](https://flutter.dev)                          | Framework UI cross-platform |
| [Geolocator](https://pub.dev/packages/geolocator)       | GPS & Location Services     |
| [flutter_map](https://pub.dev/packages/flutter_map)     | Peta OpenStreetMap          |
| [latlong2](https://pub.dev/packages/latlong2)           | Koordinat & kalkulasi jarak |
| [Hive](https://pub.dev/packages/hive)                   | Database lokal (NoSQL)      |
| [path_provider](https://pub.dev/packages/path_provider) | Akses file system           |
| [intl](https://pub.dev/packages/intl)                   | Formatting tanggal & angka  |

---

## 📁 Struktur Project

```
lib/
├── main.dart                    # Entry point aplikasi
├── models/
│   ├── workout_model.dart       # Model data Workout
│   └── workout_model.g.dart     # Hive adapter (generated)
├── screens/
│   ├── home_screen.dart         # Dashboard utama
│   ├── tracking_screen.dart     # GPS tracking dengan peta
│   ├── history_screen.dart      # Riwayat workout
│   └── workout_detail_screen.dart # Detail & peta rute
├── services/
│   ├── location_service.dart    # Service GPS
│   └── storage_service.dart     # Service Hive database
└── utils/
    ├── calorie_calculator.dart  # Kalkulasi kalori (MET)
    └── csv_helper.dart          # Export CSV/GPX
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.4.3 atau lebih baru
- Android Studio / VS Code
- Android SDK (untuk Android)
- Xcode (untuk iOS, macOS only)
- JDK 17

### Installation

1. **Clone repository**

   ```bash
   git clone https://github.com/yourusername/valefor_walktrack.git
   cd valefor_walktrack
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (jika diperlukan)

   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run aplikasi**

   ```bash
   # Debug mode
   flutter run

   # Release mode (performa lebih baik)
   flutter run --release
   ```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi
```

---

## ⚙️ Konfigurasi

### Android Permissions

File `android/app/src/main/AndroidManifest.xml` sudah dikonfigurasi dengan izin:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS Permissions

File `ios/Runner/Info.plist` sudah dikonfigurasi dengan:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi memerlukan akses lokasi untuk melacak rute perjalanan Anda.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Aplikasi memerlukan akses lokasi terus-menerus untuk tracking akurat.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

---

## 🔥 Formula Kalori (MET)

Aplikasi menggunakan **Metabolic Equivalent of Task (MET)** untuk menghitung kalori:

```
Kalori = MET × Berat Badan (kg) × Durasi (jam)
```

| Kecepatan    | Aktivitas            | MET  |
| ------------ | -------------------- | ---- |
| < 4 km/h     | Jalan lambat         | 2.5  |
| 4-5.5 km/h   | Jalan normal         | 3.5  |
| 5.5-6.5 km/h | Jalan cepat          | 4.3  |
| 6.5-8 km/h   | Jogging              | 6.0  |
| 8-9.5 km/h   | Running              | 8.3  |
| 9.5-11 km/h  | Running cepat        | 9.8  |
| 11-13 km/h   | Running sangat cepat | 11.0 |
| > 13 km/h    | Sprint               | 12.8 |

---

## 📱 Screenshots

| Home                       | Tracking                 | History                | Detail              |
| -------------------------- | ------------------------ | ---------------------- | ------------------- |
| Dashboard dengan statistik | GPS tracking dengan peta | Daftar riwayat workout | Detail rute workout |

> _Screenshots akan ditambahkan_

---

## 🐛 Troubleshooting

### Build Error: JAVA_HOME

Jika mendapat error terkait JAVA_HOME:

```powershell
# Set JAVA_HOME ke JDK 17
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"

# Atau gunakan JDK dari Android Studio
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

### GPS Tidak Berfungsi

1. Pastikan location service aktif di device
2. Berikan izin lokasi "Allow all the time"
3. Pastikan GPS/High Accuracy mode aktif

### Peta Tidak Muncul

- Periksa koneksi internet
- flutter_map menggunakan OpenStreetMap yang memerlukan internet

---

## 🗺️ Roadmap

- [ ] Background tracking service
- [ ] Notifikasi real-time
- [ ] Grafik statistik mingguan/bulanan
- [ ] Integrasi dengan Google Fit / Apple Health
- [ ] Social sharing
- [ ] Challenges & achievements
- [ ] Voice feedback saat workout
- [ ] Offline maps support

---

## 🤝 Contributing

Kontribusi sangat diterima! Silakan:

1. Fork repository
2. Buat branch fitur (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👨‍💻 Author

**Daniel** - [daniel-simorangkir.vercel.app](https://daniel-simorangkir.vercel.app/)

---

## 🙏 Acknowledgments

- [OpenStreetMap](https://www.openstreetmap.org/) - Free map tiles
- [Flutter](https://flutter.dev) - Amazing framework
- [Strava](https://www.strava.com/) - Inspiration for features

---

<p align="center">
  Made with ❤️ and Flutter
</p>
