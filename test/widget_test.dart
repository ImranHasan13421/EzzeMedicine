import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ezzemedicine/main.dart';
import 'package:ezzemedicine/providers/auth_provider.dart';
import 'package:ezzemedicine/providers/medicine_provider.dart';
import 'package:ezzemedicine/providers/order_provider.dart';

void main() {
  testWidgets('EzzeMedicine Admin app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MedicineProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: const EzzeMedicineAdminApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(EzzeMedicineAdminApp), findsOneWidget);
  });
}
