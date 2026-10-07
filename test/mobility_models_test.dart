import 'package:flutter_test/flutter_test.dart';
import 'package:dakar_bus/domain/mobility_models.dart';

void main() {
  test('never formats zero minutes as 0 mn', () {
    expect(formatWait(0), 'À l’approche');
  });

  test('formats positive wait in minutes', () {
    expect(formatWait(10), '10 mn');
  });
}
