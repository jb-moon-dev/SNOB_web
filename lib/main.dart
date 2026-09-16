import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'screens/onboarding_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'services/kakao_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Kakao SDK 초기화
  // ============================================================

  await KakaoSdk.init(
    nativeAppKey: 'f5c2a76b9629d32baa7816b9320e1453',
  );

  print('카카오 SDK 초기화 완료');

  // ============================================================
  // Kakao Map 초기화
  // ============================================================

  AuthRepository.initialize(
    appKey: '62411923f1777b7b6b056bde95e80685',
  );

  print('카카오맵 SDK 초기화 완료');

  // ============================================================
  // 앱 실행
  // ============================================================

  runApp(const SNOBApp());
}

// ============================================================
// SNOB App
// ============================================================

class SNOBApp extends StatelessWidget {
  const SNOBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SNOB',

      // ========================================================
      // SNOB 전체 디자인 테마
      // ========================================================

      theme: ThemeData(
        useMaterial3: true,

        // ======================================================
        // 기본 폰트
        // ======================================================

        fontFamily: 'Pretendard',

        // ======================================================
        // Color Scheme
        // ======================================================

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4A3A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1F4A3A),
          onPrimary: Colors.white,

          secondary: const Color(0xFF557A69),
          onSecondary: Colors.white,

          surface: Colors.white,
          onSurface: const Color(0xFF111612),

          surfaceContainerHighest: const Color(0xFFE9EEEA),

          outline: const Color(0xFFB7C2BA),
          outlineVariant: const Color(0xFFD5DDD7),

          error: const Color(0xFFC54242),
          onError: Colors.white,
        ),

        // ======================================================
        // 전체 배경
        // ======================================================

        scaffoldBackgroundColor: const Color(0xFFF3F5F1),

        // ======================================================
        // 전체 아이콘
        // ======================================================

        iconTheme: const IconThemeData(
          color: Color(0xFF1F4A3A),
          size: 24,
        ),

        // ======================================================
        // AppBar
        // ======================================================

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F5F1),
          foregroundColor: Color(0xFF111612),

          elevation: 0,
          scrolledUnderElevation: 0,

          surfaceTintColor: Colors.transparent,

          centerTitle: false,

          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.5,
          ),

          iconTheme: IconThemeData(
            color: Color(0xFF111612),
            size: 24,
          ),
        ),

        // ======================================================
        // Text Theme
        // ======================================================

        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -1.1,
            height: 1.15,
          ),

          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.9,
            height: 1.2,
          ),

          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.7,
            height: 1.2,
          ),

          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.6,
            height: 1.2,
          ),

          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.5,
            height: 1.25,
          ),

          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111612),
            letterSpacing: -0.4,
            height: 1.3,
          ),

          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111612),
            letterSpacing: -0.35,
            height: 1.3,
          ),

          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171D19),
            letterSpacing: -0.2,
            height: 1.3,
          ),

          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202721),
            letterSpacing: -0.1,
            height: 1.3,
          ),

          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF202620),
            letterSpacing: -0.1,
            height: 1.5,
          ),

          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF343C36),
            letterSpacing: -0.05,
            height: 1.45,
          ),

          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF4C554F),
            letterSpacing: 0,
            height: 1.4,
          ),

          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111612),
            letterSpacing: -0.1,
          ),

          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF252D27),
          ),

          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E4741),
          ),
        ),

        // ======================================================
        // Elevated Button
        // ======================================================

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF16382C);
                }

                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF285A46);
                }

                return const Color(0xFF1F4A3A);
              },
            ),

            foregroundColor: WidgetStateProperty.all(
              Colors.white,
            ),

            overlayColor: WidgetStateProperty.all(
              Colors.white12,
            ),

            elevation:
                WidgetStateProperty.resolveWith<double>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return 0;
                }

                return 2;
              },
            ),

            shadowColor: WidgetStateProperty.all(
              const Color(0x331F4A3A),
            ),

            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 52),
            ),

            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),

            side: WidgetStateProperty.all(
              const BorderSide(
                color: Color(0xFF173C2F),
                width: 1.0,
              ),
            ),

            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        // ======================================================
        // Filled Button
        // ======================================================

        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF16382C);
                }

                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF285A46);
                }

                return const Color(0xFF1F4A3A);
              },
            ),

            foregroundColor: WidgetStateProperty.all(
              Colors.white,
            ),

            overlayColor: WidgetStateProperty.all(
              Colors.white12,
            ),

            elevation:
                WidgetStateProperty.resolveWith<double>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return 0;
                }

                return 1;
              },
            ),

            shadowColor: WidgetStateProperty.all(
              const Color(0x331F4A3A),
            ),

            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 52),
            ),

            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),

            side: WidgetStateProperty.all(
              const BorderSide(
                color: Color(0xFF173C2F),
                width: 1.0,
              ),
            ),

            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        // ======================================================
        // Outlined Button
        // ======================================================

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFE7EDE8);
                }

                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFFF0F4F1);
                }

                return Colors.white;
              },
            ),

            foregroundColor: WidgetStateProperty.all(
              const Color(0xFF1F4A3A),
            ),

            overlayColor: WidgetStateProperty.all(
              const Color(0x101F4A3A),
            ),

            elevation: WidgetStateProperty.all(0),

            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 52),
            ),

            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),

            side:
                WidgetStateProperty.resolveWith<BorderSide?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const BorderSide(
                    color: Color(0xFF1F4A3A),
                    width: 1.5,
                  );
                }

                return const BorderSide(
                  color: Color(0xFF9EAEA4),
                  width: 1.2,
                );
              },
            ),

            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),

        // ======================================================
        // Text Button
        // ======================================================

        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF16382C);
                }

                return const Color(0xFF1F4A3A);
              },
            ),

            overlayColor: WidgetStateProperty.all(
              const Color(0x101F4A3A),
            ),

            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),

            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // ======================================================
        // Card
        // ======================================================

        cardTheme: CardThemeData(
          color: Colors.white,

          elevation: 1,

          margin: EdgeInsets.zero,

          shadowColor: const Color(0x18000000),

          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFDCE3DE),
              width: 1,
            ),
          ),
        ),

        // ======================================================
        // Input / TextField
        // ======================================================

        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          hintStyle: const TextStyle(
            color: Color(0xFF5F6862),
            fontSize: 14,
          ),

          labelStyle: const TextStyle(
            color: Color(0xFF343C36),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          floatingLabelStyle: const TextStyle(
            color: Color(0xFF1F4A3A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFD2DAD4),
              width: 1,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFC8D2CB),
              width: 1,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF1F4A3A),
              width: 1.8,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFC54242),
              width: 1.2,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFC54242),
              width: 1.8,
            ),
          ),
        ),

        // ======================================================
        // Dialog
        // ======================================================

        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,

          elevation: 4,

          shadowColor: const Color(0x30000000),

          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: Color(0xFFDDE4DE),
              width: 1,
            ),
          ),

          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111612),
            letterSpacing: -0.3,
          ),

          contentTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF343C36),
            height: 1.5,
          ),
        ),

        // ======================================================
        // Bottom Sheet
        // ======================================================

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,

          surfaceTintColor: Colors.transparent,

          elevation: 4,

          shadowColor: Color(0x30000000),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),

          showDragHandle: true,

          dragHandleColor: Color(0xFFB8C2BB),
          dragHandleSize: Size(40, 4),
        ),

        // ======================================================
        // Divider
        // ======================================================

        dividerTheme: const DividerThemeData(
          color: Color(0xFFDCE2DD),
          thickness: 1,
          space: 1,
        ),

        // ======================================================
        // Chip
        // ======================================================

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE7EDE8),

          selectedColor: const Color(0xFF1F4A3A),

          disabledColor: const Color(0xFFE3E8E5),

          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202821),
          ),

          secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFFC7D1CA),
              width: 0.8,
            ),
          ),

          side: const BorderSide(
            color: Color(0xFFC7D1CA),
            width: 0.8,
          ),
        ),

        // ======================================================
        // Checkbox
        // ======================================================

        checkboxTheme: CheckboxThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1F4A3A);
              }

              return Colors.white;
            },
          ),

          checkColor: WidgetStateProperty.all(
            Colors.white,
          ),

          side: const BorderSide(
            color: Color(0xFF7F8D84),
            width: 1.5,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        // ======================================================
        // Radio
        // ======================================================

        radioTheme: RadioThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1F4A3A);
              }

              return const Color(0xFF6F7B73);
            },
          ),
        ),

        // ======================================================
        // Switch
        // ======================================================

        switchTheme: SwitchThemeData(
          thumbColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }

              return const Color(0xFF7C8780);
            },
          ),

          trackColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1F4A3A);
              }

              return const Color(0xFFD3DAD5);
            },
          ),

          trackOutlineColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1F4A3A);
              }

              return const Color(0xFFAAB5AE);
            },
          ),
        ),

        // ======================================================
        // Progress Indicator
        // ======================================================

        progressIndicatorTheme:
            const ProgressIndicatorThemeData(
          color: Color(0xFF1F4A3A),
          linearTrackColor: Color(0xFFD8E1DA),
          circularTrackColor: Color(0xFFD8E1DA),
        ),

        // ======================================================
        // Tab Bar
        // ======================================================

        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF1F4A3A),

          unselectedLabelColor: Color(0xFF4F5952),

          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),

          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          indicatorColor: Color(0xFF1F4A3A),

          indicatorSize: TabBarIndicatorSize.label,

          dividerColor: Color(0xFFDCE2DD),
        ),

        // ======================================================
        // SnackBar
        // ======================================================

        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1D241F),

          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),

          behavior: SnackBarBehavior.floating,

          elevation: 2,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),

        // ======================================================
        // Floating Action Button
        // ======================================================

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1F4A3A),

          foregroundColor: Colors.white,

          elevation: 3,

          focusElevation: 4,
          hoverElevation: 4,
          highlightElevation: 1,

          shape: CircleBorder(),

          extendedTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),

        // ======================================================
        // List Tile
        // ======================================================

        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF1F4A3A),

          textColor: Color(0xFF111612),

          subtitleTextStyle: TextStyle(
            fontSize: 13,
            color: Color(0xFF4C554F),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
          ),

          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),

        // ======================================================
        // Tooltip
        // ======================================================

        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF1D241F),
            borderRadius: BorderRadius.circular(10),
          ),

          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),

      // ========================================================
      // 시작 화면
      // ========================================================

      home: const StartScreen(),
    );
  }
}

// ============================================================
// 시작 화면
// ============================================================

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

// ============================================================
// StartScreen State
// ============================================================

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  // ============================================================
  // 로그인 상태 확인
  // ============================================================

  Future<void> checkLogin() async {
    print('로그인 상태 확인 시작');

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    final bool hasToken =
        await KakaoAuthService.checkToken();

    print('로그인 상태 : $hasToken');

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (hasToken) {
            print('BottomNavigation으로 이동');

            return const BottomNavigation();
          }

          print('OnboardingScreen으로 이동');

          return const OnboardingScreen();
        },
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}