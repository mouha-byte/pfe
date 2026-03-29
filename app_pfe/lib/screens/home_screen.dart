import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../widgets/defect_status_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
        final latest = provider.latest;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Salsabil'),
            actions: [
              IconButton(
                tooltip: 'Rafraichir',
                onPressed: () {
                  context.read<DashboardProvider>().refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFF), Color(0xFFEFF4FC)],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () => context.read<DashboardProvider>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _OverviewCard(
                    title: latest?.defect ?? 'Aucune donnee en direct',
                    subtitle: latest == null
                        ? 'En attente de donnees depuis le backend Flask'
                        : 'Dernier statut: ${latest.statusUpper} - Priorite ${latest.priorityUpper}',
                    trailing: provider.lastUpdatedAt == null
                        ? '--'
                        : formatter.format(provider.lastUpdatedAt!.toLocal()),
                    status: latest?.statusUpper ?? '--',
                    isCritical: latest?.isCritical ?? false,
                  ),
                  const SizedBox(height: 12),
                  _QuickStats(
                    totalEvents: provider.history.length,
                    openCount: provider.history
                        .where((item) => item.statusUpper == 'OPEN')
                        .length,
                    criticalCount: provider.history
                        .where((item) => item.isCritical)
                        .length,
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _OfflineBanner(
                      message: provider.errorMessage!,
                      apiBaseUrl: provider.apiBaseUrl,
                      debugCause: provider.debugCause,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Defauts detectes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${provider.history.length}',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.history.isEmpty)
                    const _EmptyState()
                  else
                    ...provider.history.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DefectStatusCard(
                          status: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DetailScreen(status: item),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.status,
    required this.isCritical,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String status;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final topColor = isCritical ? const Color(0xFF8F2539) : const Color(0xFF1D466A);
    final bottomColor =
        isCritical ? const Color(0xFFBA4A63) : const Color(0xFF2E6A95);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
        boxShadow: [
          BoxShadow(
            color: topColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Etat du systeme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Derniere mise a jour: $trailing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.totalEvents,
    required this.openCount,
    required this.criticalCount,
  });

  final int totalEvents;
  final int openCount;
  final int criticalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Historique',
            value: '$totalEvents',
            icon: Icons.history,
            color: const Color(0xFF3A7CA5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'OPEN',
            value: '$openCount',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFCC6B1C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Critiques',
            value: '$criticalCount',
            icon: Icons.priority_high_rounded,
            color: const Color(0xFFB54058),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17334A),
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.blueGrey.shade700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.message,
    required this.apiBaseUrl,
    this.debugCause,
  });

  final String message;
  final String apiBaseUrl;
  final String? debugCause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCF9E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF49A45).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off,
              color: Color(0xFFB45C0E),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'API URL: $apiBaseUrl',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (debugCause != null) ...[
                  const SizedBox(height: 6),
                  SelectableText(
                    'Cause reelle: $debugCause',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 34, color: Colors.green.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            'Aucun defaut pour le moment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Les nouvelles anomalies apparaitront ici automatiquement.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
