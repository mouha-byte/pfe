import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/defect_status.dart';

class DefectStatusCard extends StatelessWidget {
  const DefectStatusCard({
    super.key,
    required this.status,
    required this.onTap,
  });

  final DefectStatus status;
  final VoidCallback onTap;

  Color _accentColor() {
    if (status.statusUpper == 'CLOSED') {
      return Colors.green.shade700;
    }
    if (status.priorityUpper == 'A') {
      return Colors.red.shade700;
    }
    if (status.priorityUpper == 'B') {
      return Colors.orange.shade700;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(status.timestamp.toLocal());

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: accent, width: 6)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.precision_manufacturing,
                    color: accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.defect,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17334A),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Flash: ${status.flash}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            label: status.port,
                            color: const Color(0xFFDCEAF8),
                            textColor: const Color(0xFF1D466A),
                          ),
                          _Tag(
                            label: 'Priorite ${status.priorityUpper}',
                            color: status.priorityUpper == 'A'
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            textColor: status.priorityUpper == 'A'
                                ? Colors.red.shade900
                                : Colors.orange.shade900,
                          ),
                          _Tag(
                            label: status.statusUpper,
                            color: status.statusUpper == 'OPEN'
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            textColor: status.statusUpper == 'OPEN'
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.blueGrey.shade400,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
