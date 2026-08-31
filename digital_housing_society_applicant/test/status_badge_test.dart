import 'package:flutter_test/flutter_test.dart';
import 'package:digital_housing_society/widgets/status_badge.dart';

void main() {
  test('not selected is an error state, not success', () {
    expect(badgeTypeFromStatus('Not Selected'), StatusBadgeType.error);
  });

  test('verified and approved are success states', () {
    expect(badgeTypeFromStatus('verified'), StatusBadgeType.success);
    expect(badgeTypeFromStatus('approved'), StatusBadgeType.success);
  });

  test('pending is a warning state', () {
    expect(badgeTypeFromStatus('pending'), StatusBadgeType.warning);
  });
}
