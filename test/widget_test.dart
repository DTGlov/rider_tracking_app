import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/app/app.dart';

void main() {
  testWidgets('renders the live simulator diagnostics shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    expect(find.text('Live simulator diagnostics'), findsOneWidget);
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
    expect(find.text('Remaining distance'), findsOneWidget);
    expect(find.text('Rider Tracking'), findsWidgets);
  });
}
