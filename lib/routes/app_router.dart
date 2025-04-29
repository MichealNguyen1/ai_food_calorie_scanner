// app_router.dart (router cấu hình đơn giản)
import 'package:go_router/go_router.dart';
import '../features/scan/presentation/pages/scan_page.dart';
import '../features/scan/presentation/pages/result_page.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final imagePath = state.extra as String?;
          return ResultPage(imagePath: imagePath);
        },
      ),
    ],
  );
}