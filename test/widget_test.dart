import 'package:flutter_test/flutter_test.dart';

import 'package:app_pfe/models/defect_status.dart';

void main() {
  test('DefectStatus parses a /portes/PORTE-XX payload', () {
    final status = DefectStatus.fromJson(<String, dynamic>{
      'door': 1,
      'error': 'Communication FIP',
      'mode': 'WiFi',
    }, port: 'PORTE-01');

    expect(status.port, 'PORTE-01');
    expect(status.door, 1);
    expect(status.isDoorOpen, isTrue);
    expect(status.doorLabel, 'Ouverte');
    expect(status.error, 'Communication FIP');
    expect(status.displayMode, 'WiFi');
    expect(status.hasFault, isTrue);
    expect(status.isCritical, isTrue);
    expect(status.statusLabel, 'DEFAUT');
  });

  test('An empty/OK error is treated as no fault', () {
    final ok = DefectStatus.fromJson(<String, dynamic>{
      'door': 0,
      'error': 'RAS',
      'mode': 'WiFi',
    }, port: 'PORTE-02');

    expect(ok.hasFault, isFalse);
    expect(ok.isCritical, isFalse);
    expect(ok.statusLabel, 'NORMAL');
    expect(ok.displayError, 'Aucun defaut');
    expect(ok.doorLabel, 'Fermee');
  });
}
