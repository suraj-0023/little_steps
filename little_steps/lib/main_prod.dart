import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_queue_service.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('prefs');
  await initOfflineQueue();
  final prefs = await SharedPreferences.getInstance();
  onboardingDoneSync = prefs.getBool('onboarding_done') ?? false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // App Check — Play Integrity for production
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Crashlytics — production only
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService.initialize();
  runApp(const ProviderScope(child: LittleStepsApp()));
}
