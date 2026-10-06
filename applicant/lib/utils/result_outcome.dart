/// Read-only interpretation of an individual applicant's saved balloting
/// record. A draft or pending status takes priority over provisional fields.
enum ResultOutcome { pending, selected, notSelected }

class ResultOutcomeParser {
  ResultOutcomeParser._();

  static const _pending = {
    'pending', 'draft', 'underreview', 'unpublished', 'notpublished',
  };
  static const _selected = {'selected', 'winner'};
  static const _notSelected = {'notselected', 'unsuccessful', 'failed'};

  static String _normalize(Object? raw) => (raw ?? '')
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\s-]'), '');

  static ResultOutcome fromData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return ResultOutcome.pending;

    // An unpublished admin draft must not reveal a provisional selection.
    if (data['isPublished'] == false || data['published'] == false) {
      return ResultOutcome.pending;
    }

    final fields = [
      _normalize(data['status']),
      _normalize(data['result']),
      _normalize(data['selectionStatus']),
    ];

    if (fields.any(_pending.contains)) return ResultOutcome.pending;
    for (final value in fields) {
      if (_selected.contains(value)) return ResultOutcome.selected;
      if (_notSelected.contains(value)) return ResultOutcome.notSelected;
    }

    // Legacy admin documents may publish only isSelected, with no status.
    if (data['isSelected'] == true) return ResultOutcome.selected;
    if (data['isSelected'] == false) return ResultOutcome.notSelected;
    return ResultOutcome.pending;
  }
}
