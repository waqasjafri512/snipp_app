import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/dare_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/live_provider.dart';
import 'presentation/providers/story_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/feed_screen.dart';
import 'presentation/screens/create_dare_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/chat_list_screen.dart';
import 'presentation/screens/chat_detail_screen.dart';
import 'presentation/screens/broadcaster_screen.dart';
import 'presentation/screens/viewer_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DareProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LiveProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primaryStart,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
          displayMedium: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
          displaySmall: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
          headlineMedium: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
          titleLarge: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryStart,
          secondary: AppColors.accent,
          surface: AppColors.cardBg,
          onSurface: AppColors.textMain,
          onPrimary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.bricolageGrotesque(
            color: AppColors.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: const IconThemeData(color: AppColors.textMain),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 8,
            backgroundColor: AppColors.primaryStart,
            foregroundColor: Colors.white,
            shadowColor: AppColors.primaryStart.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2EFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryStart, width: 2),
          ),
          hintStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 2,
          shadowColor: AppColors.primaryStart.withOpacity(0.07),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.signupRoute: (context) => const SignupScreen(),
        AppConstants.homeRoute: (context) => const HomeScreen(),
        AppConstants.profileRoute: (context) => const ProfileScreen(),
        AppConstants.createDareRoute: (context) => const CreateDareScreen(),
        AppConstants.chatListRoute: (context) => const ChatListScreen(),
        AppConstants.searchRoute: (context) => const SearchScreen(),
        AppConstants.notificationsRoute: (context) => const NotificationsScreen(),
        '/broadcaster': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BroadcasterScreen(
            channelName: args['channelName'],
            title: args['title'],
          );
        },
      },
    );
  }
}
