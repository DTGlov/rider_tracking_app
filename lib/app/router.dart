import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/tracking/presentation/pages/tracking_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/tracking',
  routes: [
    GoRoute(
      path: '/',
      redirect: (BuildContext context, GoRouterState state) => '/tracking',
    ),
    GoRoute(
      path: '/tracking',
      builder: (BuildContext context, GoRouterState state) {
        return const TrackingPage();
      },
    ),
  ],
);
