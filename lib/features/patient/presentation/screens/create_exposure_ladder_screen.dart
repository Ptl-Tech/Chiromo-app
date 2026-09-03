import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/exposure_ladder_model.dart';
import '../providers/exposure_providers.dart';

/// Builds a new ladder, from one of the clinic's templates or from steps the
/// patient writes themselves.
///
/// Templates lead deliberately. Writing seven graded steps from a blank screen
/// is genuinely hard work, and hardest for exactly the person who needs the
/// ladder — so starting from something already written is the default, and
/// writing your own is the quieter second option.
class CreateExposureLadderScreen extends ConsumerStatefulWidget {
  const CreateExposureLadderScreen({super.key});

  @override
  ConsumerState<CreateExposureLadderScreen> createState() =>
      _CreateExposureLadderScreenState();
}

class _CreateExposureLadderScreenState
    extends ConsumerState<CreateExposureLadderScreen> {
  final _fearController = TextEditingController();
  final _customSteps = <_StepDraft>[_StepDraft()];

  ExposureTemplate? _selected;
  bool _custom = false;
  bool _shareWithDoctor = false;
  bool _saving = false;

  @override
  void dispose() {
    _fearController.dispose();
    for (final step in _customSteps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(exposureTemplatesProvider);

    return AppScaffold(
      title: 'New Ladder',
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(exposureTemplatesProvider),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _SectionLabel('WHAT ARE YOU WORKING TOWARDS?'),
            const SizedBox(height: 8),
            TextField(
              controller: _fearController,
              maxLength: 250,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Being able to speak up in team meetings',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('CHOOSE A STARTING POINT'),
            const SizedBox(height: 4),
            const Text(
              'These are ready-made ladders you can start with. You can always '
              'move at your own pace once it is built.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final template in items)
              _TemplateTile(
                template: template,
                selected: !_custom && _selected?.code == template.code,
                onTap: () => setState(() {
                  _custom = false;
                  _selected = template;
                }),
              ),
            const SizedBox(height: 4),
            _CustomTile(
              selected: _custom,
              onTap: () => setState(() {
                _custom = true;
                _selected = null;
              }),
            ),
            if (_custom) ...[
              const SizedBox(height: 16),
              const _SectionLabel('YOUR STEPS'),
              const SizedBox(height: 4),
              const Text(
                'Start with something that feels manageable today and work up. '
                'Anything you can picture doing this week is a good first step.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: ChiromoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _customSteps.length; i++)
                _StepEditor(
                  index: i,
                  draft: _customSteps[i],
                  onRemove: _customSteps.length > 1
                      ? () => setState(() {
                          _customSteps.removeAt(i).dispose();
                        })
                      : null,
                  onChanged: () => setState(() {}),
                ),
              TextButton.icon(
                onPressed: () => setState(() => _customSteps.add(_StepDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add another step'),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _shareWithDoctor,
              onChanged: (value) => setState(() => _shareWithDoctor = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Share this with my care team',
                style: TextStyle(fontSize: 14),
              ),
              activeThumbColor: ChiromoColors.primary,
            ),
            const SizedBox(height: 16),
            ChiromoButton(
              label: 'Build my ladder',
              isLoading: _saving,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave {
    if (_saving) return false;
    if (_fearController.text.trim().isEmpty) return false;
    if (_custom) {
      return _customSteps.any((s) => s.description.trim().isNotEmpty);
    }
    return _selected != null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // Ranks are assigned by position rather than taken from the editor, so the
    // list the patient sees is the ladder they get — and so two rungs can
    // never collide on a rank.
    final steps = <ExposureStep>[];
    if (_custom) {
      var rank = 1;
      for (final draft in _customSteps) {
        final description = draft.description.trim();
        if (description.isEmpty) continue;
        steps.add(
          ExposureStep(
            rank: rank++,
            description: description,
            suggestedSuds: draft.suds,
          ),
        );
      }
    }

    try {
      final entryNo = await ref
          .read(exposureNotifierProvider.notifier)
          .createLadder(
            templateCode: _custom ? null : _selected?.code,
            fear: _fearController.text.trim(),
            steps: steps,
            shareWithDoctor: _shareWithDoctor,
          );

      if (!mounted) return;
      // Replace rather than push: coming back from a ladder should land on the
      // list, not on the form that built it.
      context.pushReplacement('/patient/cbt/exposure-ladder/$entryNo');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

/// One row of the custom-step editor. Holds its own controller so typing in
/// one step does not rebuild the others.
class _StepDraft {
  final TextEditingController controller = TextEditingController();
  int suds = 5;

  String get description => controller.text;

  void dispose() => controller.dispose();
}

class _StepEditor extends StatelessWidget {
  final int index;
  final _StepDraft draft;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _StepEditor({
    required this.index,
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ChiromoColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: ChiromoColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          TextField(
            controller: draft.controller,
            maxLength: 250,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What would you do?',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Expected distress',
                style: TextStyle(
                  fontSize: 12,
                  color: ChiromoColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: draft.suds.toDouble(),
                  min: kSudsMin.toDouble(),
                  max: kSudsMax.toDouble(),
                  divisions: kSudsMax - kSudsMin,
                  label: '${draft.suds}',
                  activeColor: ChiromoColors.primary,
                  onChanged: (value) {
                    draft.suds = value.round();
                    onChanged();
                  },
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${draft.suds}/10',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final ExposureTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? ChiromoColors.primarySurface
                : ChiromoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ChiromoColors.primary : ChiromoColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                template.icon.isEmpty ? '🪜' : template.icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${template.steps.length} steps',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: ChiromoColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ChiromoColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ChiromoColors.primary : ChiromoColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 20,
              color: ChiromoColors.textSecondary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Write my own steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: ChiromoColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ChiromoColors.textTertiary,
      ),
    );
  }
}
