import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/routes.dart';
import 'core/constants/app_globals.dart';
import 'core/services/notification_service.dart';
import 'view_model/splash_view_model.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/forget_pass_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/chat/chat_list_screen.dart';
import 'local_db/local_message_db.dart';
import 'screens/chat/new_chat_screen.dart';
// import 'screens/chat/chat_screen.dart';
import 'screens/questions/questions_screen.dart';
import 'screens/questions/question_detail_screen.dart';
import 'screens/questions/ask_question_screen.dart';
import 'view_model/auth_view_model.dart';
import 'view_model/events_view_model.dart';
import 'view_model/questions/questions_view_model.dart';
import 'view_model/profile_setup_view_model.dart';
import 'view_model/experience_view_model.dart';
import 'view_model/skills_view_model.dart';
import 'view_model/message_notification_view_model.dart';
import 'view_model/jobs_view_model.dart';
import 'view_model/social_media_view_model.dart';
import 'view_model/profile_view_model.dart';
import 'screens/screens.dart'; // ✅ Use this to access all screens
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/call_signaling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Keep existing Supabase config
  await Supabase.initialize(
    url: 'https://hgpcisbeepambgudfncr.supabase.co',
    anonKey: 'sb_publishable_E_cRI60_IKr9jBLfGmpdmQ_3B9ih8K0',
  );
  await LocalMessageDb.instance.init();
  await NotificationService.instance.initialize();
  // Start call signaling service (polling fallback)
  CallSignalingService.instance.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => EventsViewModel()),
        ChangeNotifierProvider(create: (_) => QuestionsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileSetupViewModel()),
        ChangeNotifierProvider(create: (_) => ExperienceViewModel()),
        ChangeNotifierProvider(create: (_) => SkillsViewModel()),
        ChangeNotifierProvider(create: (_) => MessageNotificationViewModel()),
        ChangeNotifierProvider(create: (_) => JobsViewModel()),
        ChangeNotifierProvider(create: (_) => SocialMediaViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Collab Bot',
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
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
          AppRoutes.otp: (context) =>
              const OtpScreen(), // Note: OtpScreen is reused but navigation logic inside VM handles context.
          AppRoutes.home: (context) => MainNavigation(key: mainNavigationKey),
          AppRoutes.leaderboard: (context) => const LeaderboardScreen(),
          AppRoutes.chatList: (context) => const ChatListScreen(),
          AppRoutes.newChat: (context) => const NewChatScreen(),
          AppRoutes.chat: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            final chatId = args?['chatId'] as String?;
            final otherName = args?['otherName'] as String? ?? 'Chat';
            final otherUserId = args?['otherUserId'] as String?;
            final otherUserRole = args?['otherUserRole'] as String?;
            if (chatId == null) {
              return const Scaffold(
                body: Center(child: Text('Chat id missing')),
              );
            }
            return ChatScreen(
              chatId: chatId,
              otherName: otherName,
              otherUserId: otherUserId,
              otherUserRole: otherUserRole,
            );
          },
          AppRoutes.questions: (context) => const QuestionsScreen(),
          AppRoutes.askQuestion: (context) => const AskQuestionScreen(),
          '${AppRoutes.questions}/detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args != null &&
                args is Map<String, dynamic> &&
                args['question'] != null) {
              return QuestionDetailScreen(question: args['question']);
            }
            return const Scaffold(
              body: Center(child: Text('Question not found')),
            );
          },
          AppRoutes.profileSetup: (context) => const ProfileSetupScreen(),
          AppRoutes.profileComplete: (context) => const ProfileCompleteScreen(),
          AppRoutes.jobListings: (context) => CareerOpportunitiesScreen(),
          AppRoutes.savedJobs: (context) => const SavedJobsScreen(),
          AppRoutes.postJob: (context) => const PostJobScreen(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.editProfile: (context) => const EditProfileScreen(),
          AppRoutes.changePassword: (context) => const ChangePasswordScreen(),
          AppRoutes.privacyPolicy: (context) => const PrivacyPolicyScreen(),
          AppRoutes.incomingCall: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return IncomingCallScreen(
              callerName: args?['callerName'] as String? ?? 'Caller',
              callerRole: args?['callerRole'] as String? ?? '',
              avatarUrl: args?['avatarUrl'] as String?,
              callType: args?['callType'] as String? ?? 'audio',
            );
          },
          AppRoutes.activeCall: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            if (args == null) {
              return const Scaffold(
                body: Center(child: Text('Missing agora params')),
              );
            }
            return ActiveCallScreen(
              appId: args['appId'] as String,
              token: args['token'] as String,
              channel: args['channel'] as String,
              uid: args['uid'] as int? ?? 0,
              enableVideo: args['enableVideo'] as bool? ?? false,
              callerName: args['callerName'] as String? ?? 'Participant',
              callerRole: args['callerRole'] as String? ?? '',
              avatarUrl: args['avatarUrl'] as String?,
              chatId: args['chatId'] as String?,
              otherUserId: args['otherUserId'] as String?,
              callId: args['callId'] as String?,
            );
          },
          AppRoutes.callEnded: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return CallEndedScreen(
              callerName: args?['callerName'] as String? ?? 'Participant',
              callerRole: args?['callerRole'] as String? ?? '',
              avatarUrl: args?['avatarUrl'] as String?,
              chatId: args?['chatId'] as String?,
              otherUserId: args?['otherUserId'] as String?,
              callDuration: args?['callDuration'] as String? ?? '00:00',
              statusLabel: args?['statusLabel'] as String? ?? 'Call ended',
            );
          },
        },
      ),
    );
  }
}
