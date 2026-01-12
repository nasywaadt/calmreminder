class SensorData {
  final int heartRate;
  final double temp;
  final double hum;

  // MPU6050
  final double accX;
  final double accY;
  final double accZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  // Stress Level
  final String stressLevel;

  SensorData({
    required this.heartRate,
    required this.temp,
    required this.hum,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.stressLevel,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final mpu = json["mpu"] ?? {};
    return SensorData(
      heartRate: json["heartRate"] ?? 0,
      temp: (json["temp"] ?? 0.0).toDouble(),
      hum: (json["hum"] ?? 0.0).toDouble(),
      accX: (mpu["accX"] ?? 0.0).toDouble(),
      accY: (mpu["accY"] ?? 0.0).toDouble(),
      accZ: (mpu["accZ"] ?? 0.0).toDouble(),
      gyroX: (mpu["gyroX"] ?? 0.0).toDouble(),
      gyroY: (mpu["gyroY"] ?? 0.0).toDouble(),
      gyroZ: (mpu["gyroZ"] ?? 0.0).toDouble(),
      stressLevel: "Unknown",
    );
  }

  SensorData copyWithStress(String level) {
    return SensorData(
      heartRate: heartRate,
      temp: temp,
      hum: hum,
      accX: accX,
      accY: accY,
      accZ: accZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      stressLevel: level,
    );
  }
}
