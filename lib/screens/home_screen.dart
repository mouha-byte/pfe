import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/defect_status.dart';
import '../providers/dashboard_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
        final monitoredPorts = provider.monitoredPorts;
        final latestByPort = <String, DefectStatus>{
          for (final item in provider.latestByPort) item.port: item,
        };
        final faultCount = provider.faultCount;

        return Scaffold(
          // appBar: AppBar(
          //   title: const Text('Dashboard Salsabil'),
          //   actions: [
          //     _ConnectionBadge(isRealtime: provider.isRealtime),
          //     IconButton(
          //       tooltip: 'Rafraichir',
          //       onPressed: () {
          //         context.read<DashboardProvider>().refresh();
          //       },
          //       icon: const Icon(Icons.refresh),
          //     ),
          //   ],
          // ),
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
                    title: faultCount > 0
                        ? '$faultCount porte(s) en defaut'
                        : 'Toutes les portes sont normales',
                    subtitle:
                        '${provider.openDoorCount} porte(s) ouverte(s) - '
                        '${provider.activeCount}/${monitoredPorts.length} portes detectees',
                    trailing: provider.lastUpdatedAt == null
                        ? '--'
                        : formatter.format(provider.lastUpdatedAt!.toLocal()),
                    status: faultCount > 0 ? 'DEFAUT' : 'NORMAL',
                    isCritical: faultCount > 0,
                  ),
                  const SizedBox(height: 12),
                  _QuickStats(
                    totalPorts: monitoredPorts.length,
                    faultCount: faultCount,
                    openDoorCount: provider.openDoorCount,
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
                  _PortSectionHeader(
                    totalPorts: monitoredPorts.length,
                    activePorts: provider.activeCount,
                  ),
                  const SizedBox(height: 10),
                  _PortStatusTable(
                    ports: monitoredPorts,
                    latestByPort: latestByPort,
                    onOpenDetail: (item) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(status: item),
                        ),
                      );
                    },
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
    final topColor = isCritical
        ? const Color(0xFF8F2539)
        : const Color(0xFF1D466A);
    final bottomColor = isCritical
        ? const Color(0xFFBA4A63)
        : const Color(0xFF2E6A95);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
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
    required this.totalPorts,
    required this.faultCount,
    required this.openDoorCount,
  });

  final int totalPorts;
  final int faultCount;
  final int openDoorCount;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _StatChip(
        label: 'Portes',
        value: '$totalPorts',
        icon: Icons.meeting_room_rounded,
        color: const Color(0xFF3A7CA5),
      ),
      _StatChip(
        label: 'Defauts',
        value: '$faultCount',
        icon: Icons.error_rounded,
        color: const Color(0xFFB54058),
      ),
      _StatChip(
        label: 'Ouvertes',
        value: '$openDoorCount',
        icon: Icons.lock_open_rounded,
        color: const Color(0xFFCC6B1C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                chips[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: chips[i]),
            ],
          ],
        );
      },
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
                  'Firebase: $apiBaseUrl',
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

class _PortSectionHeader extends StatelessWidget {
  const _PortSectionHeader({
    required this.totalPorts,
    required this.activePorts,
  });

  final int totalPorts;
  final int activePorts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau des portes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoBadge(label: 'Portes', value: '$totalPorts'),
                  _InfoBadge(label: 'Actives', value: '$activePorts'),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Tableau des portes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _InfoBadge(label: 'Portes', value: '$totalPorts'),
            const SizedBox(width: 8),
            _InfoBadge(label: 'Actives', value: '$activePorts'),
          ],
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PortStatusTable extends StatelessWidget {
  const _PortStatusTable({
    required this.ports,
    required this.latestByPort,
    required this.onOpenDetail,
  });

  final List<String> ports;
  final Map<String, DefectStatus> latestByPort;
  final ValueChanged<DefectStatus> onOpenDetail;

  Color _statusColor(DefectStatus? item) {
    if (item == null) {
      return const Color(0xFF7E8A96);
    }
    if (item.hasFault) {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF2E7D32);
  }

  String _timeLabel(DefectStatus? item) {
    if (item == null) {
      return '--';
    }
    return DateFormat('HH:mm:ss').format(item.timestamp.toLocal());
  }

  Widget _metaTag(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCompactRows(BuildContext context) {
    return Column(
      children: ports
          .map((port) {
            final item = latestByPort[port];
            final statusColor = _statusColor(item);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item == null ? null : () => onOpenDetail(item),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                      ),
                    ),
                    color: item?.hasFault ?? false
                        ? const Color(0xFFFFF3F0)
                        : Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            port,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF17334A),
                                ),
                          ),
                          const Spacer(),
                          _metaTag(
                            context,
                            label: item?.statusLabel ?? 'EN ATTENTE',
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item?.displayError ?? 'Aucune donnee',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2A445A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _metaTag(
                            context,
                            label: 'Porte ${item?.doorLabel ?? '--'}',
                            color: item == null
                                ? const Color(0xFF7E8A96)
                                : item.isDoorOpen
                                ? const Color(0xFFA3192E)
                                : const Color(0xFF2E7D32),
                          ),
                          _metaTag(
                            context,
                            label: 'Mode ${item?.displayMode ?? '--'}',
                            color: const Color(0xFF365A7A),
                          ),
                          _metaTag(
                            context,
                            label: 'Maj ${_timeLabel(item)}',
                            color: const Color(0xFF5C6F82),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: const Color(0xFF17334A),
      fontWeight: FontWeight.bold,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: headingStyle,
        columnSpacing: 22,
        horizontalMargin: 14,
        headingRowHeight: 42,
        dataRowMinHeight: 50,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('Porte')),
          DataColumn(label: Text('Etat')),
          DataColumn(label: Text('Defaut')),
          DataColumn(label: Text('Porte')),
          DataColumn(label: Text('Mode')),
          DataColumn(label: Text('Maj')),
        ],
        rows: ports
            .map((port) {
              final item = latestByPort[port];
              final statusColor = _statusColor(item);

              return DataRow(
                onSelectChanged: item == null
                    ? null
                    : (_) => onOpenDetail(item),
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFEAF3FF);
                  }
                  if (item?.hasFault ?? false) {
                    return const Color(0xFFFFF3F0);
                  }
                  return null;
                }),
                cells: [
                  DataCell(
                    Text(
                      port,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17334A),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item?.statusLabel ?? 'EN ATTENTE',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        item?.displayError ?? 'Aucune donnee',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item?.doorLabel ?? '--',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: item == null
                            ? const Color(0xFF6B7683)
                            : item.isDoorOpen
                            ? const Color(0xFFA3192E)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  DataCell(Text(item?.displayMode ?? '--')),
                  DataCell(Text(_timeLabel(item))),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5E0ED)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A4468), Color(0xFF2A6B98)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_chart_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dernier etat de chaque porte',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!compact)
                      Text(
                        'Touchez une ligne pour le detail',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
              if (compact)
                _buildCompactRows(context)
              else
                _buildDesktopTable(context),
            ],
          ),
        );
      },
    );
  }
}
