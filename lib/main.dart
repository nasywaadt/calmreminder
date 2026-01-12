// main.dart
import 'package:calmreminder/auth/login_page.dart';
import 'package:calmreminder/pages/user/user_dashboard.dart'; // Sesuaikan path ini
import 'package:calmreminder/pages/admin/admin_dashboard.dart'; // Sesuaikan path ini
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/mqtt/mqtt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MqttService()..connect(),
        ),
      ],
      child: MaterialApp(
        title: 'Calm Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        // Rute awal saat aplikasi dibuka
        initialRoute: '/login',
        
        // Tabel Rute (Named Routes)
        routes: {
          '/login': (context) => const LoginPage(),
          '/user_dashboard': (context) => const DashboardPage(),
          '/admin_dashboard': (context) => const AdminDashboardPage(),
        },

        // Opsional: Tetap pasang home sebagai fallback
        home: const LoginPage(),
      ),
    );
  }
}