import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/main.dart';
import 'package:lexifold/utils/routes_name.dart';

import '../../providers/core/firebase_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    //Hiệu ứng mờ dần sang rõ
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    //Hiệu ứng phóng to nhẹ nhàng từ 85% -> 100%
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    ref
        .read(authStateProvider)
        .when(
          data: (user) {
            if (!mounted) return;

            Future.delayed(const Duration(milliseconds: 2000), () {
              if (user != null) {
                navigatorKey.currentState?.pushReplacementNamed(
                  RoutesName.mainScreen,
                );
              } else {
                navigatorKey.currentState?.pushReplacementNamed(
                  RoutesName.authScreen,
                );
              }
            });
          },
          error: (Object error, StackTrace stackTrace) {
            navigatorKey.currentState?.pushReplacementNamed(
              RoutesName.authScreen,
            );
          },
          loading: () {
            _listenOnce();
          },
        );
  }

  void _listenOnce() {
    //Tự động close khi widget dispose
    ref.listenManual(authStateProvider, (prev, next) {
      next.whenData((user) {
        if (!mounted) return;

        Future.delayed(const Duration(milliseconds: 2000), () {
          if (user != null) {
            navigatorKey.currentState?.pushReplacementNamed(
              RoutesName.mainScreen,
            );
          } else {
            navigatorKey.currentState?.pushReplacementNamed(
              RoutesName.authScreen,
            );
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.auto_awesome_sharp,
                      size: 100,
                      color: Colors.blueAccent,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
