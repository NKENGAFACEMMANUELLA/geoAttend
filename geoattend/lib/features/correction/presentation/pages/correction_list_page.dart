import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/correction.dart';
import '../cubit/correction_cubit.dart';

class CorrectionListPage extends StatefulWidget {
  const CorrectionListPage({super.key});

  @override
  State<CorrectionListPage> createState() => _CorrectionListPageState();
}

class _CorrectionListPageState extends State<CorrectionListPage> {
  static const _tabs = ['All', 'Pending', 'Approved', 'Rejected'];
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Correction Details',
      child: AsyncBuilder<CorrectionCubit, List<CorrectionRequest>>(
        onRetry: () => context.read<CorrectionCubit>().load(),
        builder: (context, all) {
          final list = _tab == 0 ? all : all.where((r) => r.status.index == _tab - 1).toList();
          return Column(children: [
            FilterTabBar(labels: _tabs, selected: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? EmptyStateView(
                      icon: Icons.edit_note,
                      title: 'No correction requests',
                      message: _tab == 0 ? 'Requests you submit will appear here.' : 'Nothing under ${_tabs[_tab]} yet.')
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 22),
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Clock Correction',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.6)),
                              const SizedBox(height: 4),
                              Text(
                                  '${Fmt.dateLong(r.date)} · ${Fmt.time(r.requestedClockIn)} – ${Fmt.time(r.requestedClockOut)}',
                                  style: const TextStyle(fontSize: 13)),
                            ]),
                          ),
                          StatusPill.request(r.status),
                        ]);
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
