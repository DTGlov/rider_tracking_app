import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/tracking/domain/repositories/tracking_repository.dart';
import '../features/tracking/presentation/view_models/tracking_view_model.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'tracking_composition.dart';
import 'tracking_source_config.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = TrackingAppConfig.fromEnvironment();

    return Provider<TrackingRepository>(
      create: (_) => createTrackingRepository(appConfig),
      child: Builder(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (_) => TrackingViewModel(
              repository: context.read<TrackingRepository>(),
            ),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Rider Tracking',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeMode.system,
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
