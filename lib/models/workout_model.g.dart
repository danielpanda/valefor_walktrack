// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      date: fields[0] as DateTime,
      distanceKm: fields[1] as double,
      durationSeconds: fields[2] as int,
      route: (fields[3] as List).cast<LatLng>(),
      caloriesBurned: fields[4] as double? ?? 0.0,
      activityType: fields[5] as ActivityType? ?? ActivityType.walking,
      avgSpeedKmh: fields[6] as double? ?? 0.0,
      pace: fields[7] as String? ?? '--:--',
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.distanceKm)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.route)
      ..writeByte(4)
      ..write(obj.caloriesBurned)
      ..writeByte(5)
      ..write(obj.activityType)
      ..writeByte(6)
      ..write(obj.avgSpeedKmh)
      ..writeByte(7)
      ..write(obj.pace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
