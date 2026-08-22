import 'package:flutter_test/flutter_test.dart';

import 'package:fontakip/main.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const FonTakipApp());
    await tester.pump();

    expect(find.text('Finans Merkezi'), findsOneWidget);
    expect(find.text('🏠 Genel Portföyüm'), findsOneWidget);
    expect(find.text('FON'), findsOneWidget);
    expect(find.text('HİSSE'), findsOneWidget);
  });
}
