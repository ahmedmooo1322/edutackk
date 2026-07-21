import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The Wiretap source bundle loads test bindings', (tester) async {
    expect(tester.binding, isNotNull);
  });
}
