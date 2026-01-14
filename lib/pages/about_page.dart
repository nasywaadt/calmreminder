import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final String youtubeUrl =
      'https://youtube.com/shorts/X79H4L6PUFw?feature=share';

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(youtubeUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $youtubeUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CalmReminder'),
            const SizedBox(height: 8),
            const Text(
              'CalmReminder adalah aplikasi smart mental health monitoring '
              'yang dikembangkan untuk membantu pengguna memantau kondisi '
              'kesehatan mental melalui data detak jantung dan suhu tubuh '
              'secara real-time.',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Tema Aplikasi'),
            const Text(
              'Kesehatan (Mental Health Monitoring)',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Platform & Teknologi'),
            const Text(
              '• Flutter (Mobile Client)\n'
              '• Firebase (Backend & Database)\n'
              '• MQTT & HTTP JSON\n'
              '• ESP32 (IoT Device)',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Developer'),
            const Text(
              '• 152023006 – Nasywa Adita Zain (Admin)\n'
              '• 152023038 – Taras Al Fariz (User)',
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Demo Aplikasi'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _launchURL,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Lihat Demo di YouTube'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }
}