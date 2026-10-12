import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashState {
  final bool isLoading;

  const SplashState({this.isLoading = true});
}

class SplashController extends Notifier<SplashState> {
  @override
  SplashState build() => const SplashState();

  void finishLoading() {
    state = const SplashState(isLoading: false);
  }
}

final splashProvider = NotifierProvider<SplashController, SplashState>(
  SplashController.new,
);
