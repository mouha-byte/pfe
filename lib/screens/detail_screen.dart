import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/defect_status.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.status});

  final DefectStatus status;

  String _faultExplanation(DefectStatus status) {
    if (!status.hasFault) {
      return 'Aucun defaut actif: fonctionnement normal.';
    }
    final error = status.error.trim().toUpperCase();
    if (error.contains('FIP') || error.contains('COMMUNICATION')) {
      return 'Probleme de communication detecte (bus FIP). '
          'Verifiez le cablage et la liaison entre les equipements.';
    }
    if (status.isDoorOpen) {
      return 'Defaut signale alors que la porte est ouverte. '
          'Verifiez l acces et fermez la porte si necessaire.';
    }
    return 'Defaut signale par l appareil. Une intervention est conseillee.';
  }

  @override
  Widget build(BuildContext context) {
    final color = status.hasFault
        ? Colors.red.shade700
        : Colors.green.shade700;

    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(status.timestamp.toLocal());

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Defaut')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            status.displayError,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Porte', value: status.port),
                    _InfoRow(label: 'Etat', value: status.statusLabel),
                    _InfoRow(label: 'Position', value: status.doorLabel),
                    _InfoRow(label: 'Mode', value: status.displayMode),
                    _InfoRow(label: 'Releve le', value: formattedDate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explication',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _faultExplanation(status),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
