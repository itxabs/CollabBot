import 'package:collab_bot/screens/login.dart';
import 'package:collab_bot/screens/signUp.dart';
import 'package:collab_bot/view_models/auth_view_model.dart';
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
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/signup',
        routes: {
          '/signup': (context) => SignupScreen(),
          '/login': (context) => LoginScreen(),
          // '/home': (context) => HomeScreen(), 
        },
      ),
    );
  }
}
