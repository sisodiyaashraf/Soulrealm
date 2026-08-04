import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations and system bar stylings
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const SoulrealmApp());
}

class SoulrealmApp extends StatelessWidget {
  const SoulrealmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soulrealm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07090F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F121F),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

