import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/routes.dart';
import 'view_model/splash_view_model.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/forget_pass_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'view_model/auth_view_model.dart';
import 'screens/main_navigation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep existing Supabase config
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
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CollabBot',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.indigo, // Fallback
          // We can better configure theme using AppColors later
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const SignupScreen(),
          AppRoutes.forgotPassword: (context) => const ForgetPassScreen(),
          AppRoutes.otp: (context) => const OtpScreen(), // Note: OtpScreen is reused but navigation logic inside VM handles context.
          AppRoutes.home: (context) => const MainNavigation(),
        },
      ),
    );
  }
}
