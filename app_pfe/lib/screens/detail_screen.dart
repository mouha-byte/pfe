import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/defect_status.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.status});

  final DefectStatus status;

  String _flashExplanation(int flash) {
    if (flash <= 0) {
      return 'Aucun flash detecte: fonctionnement stable.';
    }
    if (flash <= 2) {
      return 'Niveau faible: verification preventive recommandee.';
    }
    if (flash <= 4) {
      return 'Niveau modere: intervention technique conseillee.';
    }
    return 'Niveau eleve: intervention urgente requise.';
  }

  @override
  Widget build(BuildContext context) {
    final color = status.statusUpper == 'CLOSED'
        ? Colors.green.shade700
        : status.priorityUpper == 'A'
        ? Colors.red.shade700
        : Colors.orange.shade700;

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
                            status.defect,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Port', value: status.port),
                    _InfoRow(
                      label: 'Flash count',
                      value: status.flash.toString(),
                    ),
                    _InfoRow(label: 'Priorite', value: status.priorityUpper),
                    _InfoRow(label: 'Statut', value: status.statusUpper),
                    _InfoRow(label: 'Horodatage', value: formattedDate),
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
                      'Explication du flash count',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _flashExplanation(status.flash),
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
