import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'provider.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Temporarily disable FCM initialization to test
  print('Skipping FCM initialization for testing...');
  // try {
  //   await FcmService.initialize();
  // } catch (e) {
  //   print('FCM initialization failed: $e');
  //   // Continue without FCM - app will still work
  // }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSetting>(
      valueListenable: themeSetting,
      builder: (context, setting, _) {
        Brightness platformBrightness =
            MediaQuery.of(context).platformBrightness;

        bool isDark;
        if (setting == ThemeSetting.system) {
          isDark = platformBrightness == Brightness.dark;
        } else {
          isDark = setting == ThemeSetting.dark;
        }

        return ChangeNotifierProvider(
          create: (context) => AppProvider(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primarySwatch: Colors.green,
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();      
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Starting app initialization...');
      
      // Initialize connectivity service
      print('Initializing connectivity service...');
      await ConnectivityService.initialize();
      print('Connectivity service initialized');
      
      // Initialize notifications
      print('Initializing notification service...');
      await NotificationService.initialize();
      print('Notification service initialized');
      
      // Temporarily disable FCM to test if it's causing the issue
      print('Skipping FCM token retrieval for testing...');
      // try {
      //   await FcmService.getToken();
      //   print('FCM token retrieved');
      // } catch (e) {
      //   print('FCM token failed: $e');
      //   // Continue without FCM token
      // }
      
      // Initialize the app provider
      print('Initializing app provider...');
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.initialize();
      print('App provider initialized');
      
      // Wait for splash screen duration
      print('Waiting for splash screen...');
      await Future.delayed(const Duration(seconds: 3));
      
      // Navigate directly to home screen - terms and policies are only in navigation
      print('Navigating to home screen...');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Error during app initialization: $e');
      // Navigate to home screen even if initialization failed
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/midwest_logo.jpg',
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Midwest Grocery Store',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
