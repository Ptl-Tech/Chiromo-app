import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';

import 'medications_screen.dart';
import 'visit_notes_screen.dart';

/// Everything the clinic has recorded for this patient, in one place.
///
/// Previously this read Supabase and rendered `clinicalNotes` — the notes a
/// doctor writes for other clinicians — straight to the patient. Both tabs now
/// come from Business Central, and the notes tab shows only what a doctor
/// wrote *for* the patient and released. Clinical documentation is a separate
/// record and is deliberately not served to the app at all: it is written in a
/// register that reads badly, and occasionally harmfully, to the person it is
/// about.
class PatientRecordsScreen extends ConsumerStatefulWidget {
  /// Which tab to open on. The medication list is the more frequent errand —
  /// someone standing at the cupboard wondering about a dose — so it leads.
  final int initialTab;

  const PatientRecordsScreen({this.initialTab = 0, super.key});

  @override
  ConsumerState<PatientRecordsScreen> createState() =>
      _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Records',
      showBack: true,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: ChiromoColors.primary,
            unselectedLabelColor: ChiromoColors.textSecondary,
            indicatorColor: ChiromoColors.primary,
            tabs: const [
              Tab(text: 'Medications'),
              Tab(text: 'Notes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [MedicationsView(), VisitNotesView()],
            ),
          ),
        ],
      ),
    );
  }
}
