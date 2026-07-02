import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sisa_pintar/main.dart';

void main() {
  testWidgets('SisaPintar app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsProvider(),
        child: const SisaPintarApp(),
      ),
    );
    // App renders without errors
    expect(find.byType(SisaPintarApp), findsOneWidget);
  });
}
