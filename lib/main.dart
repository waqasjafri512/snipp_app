import 'package:firebase_core/firebase_core.dart';
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
import 'presentation/providers/group_provider.dart';
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
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/theme_center_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully.');
    
    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(NotificationService.firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('\n======================================================');
    print('🚨 FIREBASE NOT CONFIGURED YET!');
    print('You need to run "flutterfire configure" in your terminal.');
    print('The app will likely crash or fail to login until you do.');
    print('======================================================\n');
  }

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
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final currentTheme = themeProv.currentTheme;
        
        return MaterialApp(
          scaffoldMessengerKey: messengerKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: themeProv.currentThemeIndex == 1 ? Brightness.dark : Brightness.light,
            primaryColor: currentTheme.primaryStart,
            scaffoldBackgroundColor: currentTheme.background,
            textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
              displayLarge: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                color: currentTheme.textMain,
              ),
              displayMedium: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                color: currentTheme.textMain,
              ),
              displaySmall: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                color: currentTheme.textMain,
              ),
              headlineMedium: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                color: currentTheme.textMain,
              ),
              titleLarge: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                color: currentTheme.textMain,
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: currentTheme.primaryStart,
              brightness: themeProv.currentThemeIndex == 1 ? Brightness.dark : Brightness.light,
              primary: currentTheme.primaryStart,
              secondary: currentTheme.primaryEnd,
              surface: themeProv.currentThemeIndex == 1 ? const Color(0xFF1A1A1A) : Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: currentTheme.background,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.bricolageGrotesque(
                color: currentTheme.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              iconTheme: IconThemeData(color: currentTheme.textMain),
            ),
          ),
          home: const SplashScreen(),
          routes: {
            AppConstants.homeRoute: (context) => const HomeScreen(),
            AppConstants.profileRoute: (context) => const ProfileScreen(),
            AppConstants.createDareRoute: (context) => const CreateDareScreen(),
            AppConstants.chatListRoute: (context) => const ChatListScreen(),
            AppConstants.searchRoute: (context) => const SearchScreen(),
            AppConstants.notificationsRoute: (context) => const NotificationsScreen(),
            '/theme-center': (context) => const ThemeCenterScreen(),
            '/broadcaster': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return BroadcasterScreen(
                channelName: args['channelName'],
                title: args['title'],
              );
            },
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppConstants.loginRoute || settings.name == AppConstants.signupRoute) {
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return settings.name == AppConstants.loginRoute 
                    ? const LoginScreen() 
                    : const SignupScreen();
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
