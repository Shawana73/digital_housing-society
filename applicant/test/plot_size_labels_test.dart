import 'package:flutter_test/flutter_test.dart';
import 'package:digital_housing_society/utils/plot_size_labels.dart';

void main() {
  test('legacy bare 15 and 15 Marla produce a single display option', () {
    final options = {'15', '15 Marla', ' 15 marla ', '10 Marla'}
        .map(PlotSizeLabels.display)
        .toSet();
    expect(options, containsAll(['15 Marla', '10 Marla']));
    expect(options.length, 2);
  });

  test('legacy numeric and string sizes match 15 Marla filtering', () {
    expect(PlotSizeLabels.matchesFilter(15, '15 Marla'), isTrue);
    expect(PlotSizeLabels.matchesFilter('15', '15 Marla'), isTrue);
    expect(PlotSizeLabels.matchesFilter(' 15 MARLA ', '15 Marla'), isTrue);
    expect(PlotSizeLabels.matchesFilter('10 Marla', '15 Marla'), isFalse);
    expect(PlotSizeLabels.matchesFilter('5 Marla', 'All'), isTrue);
  });

  test('other plot sizes and missing data are unchanged', () {
    expect(PlotSizeLabels.display('5 Marla'), '5 Marla');
    expect(PlotSizeLabels.display('1 Kanal'), '1 Kanal');
    expect(PlotSizeLabels.display(null), '');
  });
}
