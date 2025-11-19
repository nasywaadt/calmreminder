class StressLogic {
  static String analyze({
    required int heartRate,
    required double temp,
    required double accX,
    required double accY,
    required double accZ,
  }) {
    double movement =
        (accX.abs() + accY.abs() + accZ.abs()) / 3; // aktivitas rata-rata

    // 🔵 RELAX (tenang)
    if (heartRate < 85 && movement < 1.5 && temp < 37) {
      return "Relax";
    }

    // 🟡 MODERATE STRESS
    if ((heartRate >= 85 && heartRate < 110) ||
        (movement >= 1.5 && movement < 3)) {
      return "Mild Stress";
    }

    // 🔴 HIGH STRESS / ANXIOUS
    if (heartRate >= 110 || movement >= 3 || temp >= 38) {
      return "High Stress";
    }

    return "Unknown";
  }
}
