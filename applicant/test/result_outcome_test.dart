import 'package:flutter_test/flutter_test.dart';
import 'package:digital_housing_society/utils/result_outcome.dart';

void main() {
  test('missing or draft result never becomes selected', () {
    expect(ResultOutcomeParser.fromData(null), ResultOutcome.pending);
    expect(ResultOutcomeParser.fromData({}), ResultOutcome.pending);
    expect(ResultOutcomeParser.fromData({
      'status': 'draft', 'isSelected': true,
    }), ResultOutcome.pending);
    expect(ResultOutcomeParser.fromData({
      'status': 'pending', 'isSelected': false,
    }), ResultOutcome.pending);
    expect(ResultOutcomeParser.fromData({
      'isPublished': false, 'status': 'Selected',
    }), ResultOutcome.pending);
    expect(ResultOutcomeParser.fromData({
      'published': false, 'isSelected': true,
    }), ResultOutcome.pending);
  });

  test('recognizes published status and legacy boolean records', () {
    expect(ResultOutcomeParser.fromData({
      'status': 'Selected',
    }), ResultOutcome.selected);
    expect(ResultOutcomeParser.fromData({
      'status': 'Not Selected',
    }), ResultOutcome.notSelected);
    expect(ResultOutcomeParser.fromData({
      'isSelected': true,
    }), ResultOutcome.selected);
    expect(ResultOutcomeParser.fromData({
      'isSelected': false,
    }), ResultOutcome.notSelected);
  });

  test('reads a selectionStatus when generic status is published', () {
    expect(ResultOutcomeParser.fromData({
      'status': 'published', 'selectionStatus': 'winner',
    }), ResultOutcome.selected);
    expect(ResultOutcomeParser.fromData({
      'status': 'published', 'result': 'not_selected',
    }), ResultOutcome.notSelected);
  });
}
