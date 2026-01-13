import 'package:collab_bot/screens/auth/forget_pass_screen.dart';
import 'package:collab_bot/screens/auth/login_screen.dart';
import 'package:collab_bot/screens/main_navigation.dart';
import 'package:collab_bot/screens/onboarding/onboarding_screen.dart';
import 'package:collab_bot/screens/auth/signup_screen.dart';
import 'package:collab_bot/screens/splash/splash_screen.dart';
import 'package:collab_bot/view_models/auth_view_model.dart';
import 'package:collab_bot/view_models/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hgpcisbeepambgudfncr.supabase.co',
    anonKey: 'sb_publishable_E_cRI60_IKr9jBLfGmpdmQ_3B9ih8K0',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Collab Bot',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/onboarding': (context) => OnboardingScreen(),
          '/signup': (context) => SignupScreen(),
          '/login': (context) => LoginScreen(),
          '/forget-pass': (context) => ForgetPass(),
          '/main-navigation': (context) => MainNavigation(),
        },
      ),
    );
  }
}
