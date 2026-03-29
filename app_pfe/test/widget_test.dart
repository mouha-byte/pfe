import 'package:flutter_test/flutter_test.dart';

import 'package:app_pfe/models/defect_status.dart';

void main() {
  test('DefectStatus parses json payload', () {
    final status = DefectStatus.fromJson(<String, dynamic>{
      'flash': 4,
      'defect': 'Capteur position',
      'priority': 'B',
      'status': 'OPEN',
      'timestamp': '2026-01-01T10:00:00',
    });

    expect(status.flash, 4);
    expect(status.defect, 'Capteur position');
    expect(status.priorityUpper, 'B');
    expect(status.statusUpper, 'OPEN');
    expect(status.isCritical, isTrue);
  });
}
