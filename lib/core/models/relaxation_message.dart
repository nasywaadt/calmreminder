// lib/core/models/relaxation_message.dart

class RelaxationMessage {
  final String title;
  final String message;
  final String emoji;
  final List<String> tips;
  final String stressLevel;

  RelaxationMessage({
    required this.title,
    required this.message,
    required this.emoji,
    required this.tips,
    required this.stressLevel,
  });

  // Simulasi data dari admin
  static List<RelaxationMessage> getMessagesForStressLevel(String stressLevel) {
    if (stressLevel == "Relax") {
      return [
        RelaxationMessage(
          title: "You're Doing Great!",
          message: "Your stress levels are low. Keep maintaining this peaceful state.",
          emoji: "🌟",
          stressLevel: "Relax",
          tips: [
            "Continue your current routine",
            "Practice gratitude meditation",
            "Enjoy your favorite hobby",
            "Get quality sleep tonight",
          ],
        ),
      ];
    } else if (stressLevel == "Mild Stress") {
      return [
        RelaxationMessage(
          title: "Take a Breath",
          message: "You're experiencing mild stress. Let's work on bringing your calm back.",
          emoji: "🌊",
          stressLevel: "Mild Stress",
          tips: [
            "Try 5-minute breathing exercises",
            "Take a short walk outside",
            "Listen to calming music",
            "Drink a glass of water",
            "Stretch your body gently",
          ],
        ),
      ];
    } else {
      return [
        RelaxationMessage(
          title: "High Stress Detected",
          message: "Your body is showing signs of high stress. Please take immediate action.",
          emoji: "🆘",
          stressLevel: "High Stress",
          tips: [
            "Stop what you're doing and rest",
            "Practice deep breathing (4-7-8 technique)",
            "Contact someone you trust",
            "Drink cold water",
            "Remove yourself from stressful environment",
            "Consider professional help if needed",
          ],
        ),
      ];
    }
  }
}