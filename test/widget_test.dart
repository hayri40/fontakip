import 'package:flutter_test/flutter_test.dart';

import 'package:fontakip/main.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const FonTakipApp());
    await tester.pump();

    expect(find.text('FonTakip'), findsOneWidget);
    expect(find.text('Ara'), findsOneWidget);
    expect(find.text('İşlemler'), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);
  });
}
