/// Normalizes legacy plot-size labels only in the applicant presentation layer.
/// Firestore records and the admin schema are never rewritten.
class PlotSizeLabels {
  PlotSizeLabels._();

  static String display(Object? value) {
    final text = (value ?? '').toString().trim();
    if (text.toLowerCase() == '15' ||
        RegExp(r'^15\s+marla$', caseSensitive: false).hasMatch(text)) {
      return '15 Marla';
    }
    return text;
  }

  /// Selection is made against the same display label used in the filter.
  /// Both old `15` and the newer `15 Marla` match one visible filter option.
  static bool matchesFilter(Object? storedSize, String selected) {
    if (selected == 'All') return true;
    String normalize(Object? value) => display(value)
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalize(storedSize) == normalize(selected);
  }
}
