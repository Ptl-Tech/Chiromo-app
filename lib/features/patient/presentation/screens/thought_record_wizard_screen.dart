import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/thought_record_model.dart';
import '../providers/thought_providers.dart';

/// Works one thought through, a step at a time.
///
/// Stepped rather than a single long form on purpose. The exercise is a
/// sequence — notice the thought, rate it, look at the evidence, then
/// reappraise — and seeing the reappraisal box before doing the looking
/// invites someone to skip to "I should think more positively", which is the
/// failure mode the technique exists to avoid.
class ThoughtRecordWizardScreen extends ConsumerStatefulWidget {
  const ThoughtRecordWizardScreen({super.key});

  @override
  ConsumerState<ThoughtRecordWizardScreen> createState() =>
      _ThoughtRecordWizardScreenState();
}

class _ThoughtRecordWizardScreenState
    extends ConsumerState<ThoughtRecordWizardScreen> {
  final _controller = PageController();
  final _situation = TextEditingController();
  final _thought = TextEditingController();
  final _emotion = TextEditingController();
  final _balanced = TextEditingController();

  final _for = <TextEditingController>[TextEditingController()];
  final _against = <TextEditingController>[TextEditingController()];

  int _step = 0;
  int _before = 5;
  int _after = 5;
  bool _saving = false;

  static const _stepCount = 6;

  @override
  void dispose() {
    _controller.dispose();
    _situation.dispose();
    _thought.dispose();
    _emotion.dispose();
    _balanced.dispose();
    for (final c in [..._for, ..._against]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Thought Record',
      body: Column(
        children: [
          _Progress(step: _step, total: _stepCount),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _Step(
                  title: 'What happened?',
                  subtitle:
                      'Describe the situation plainly — where you were, who '
                      'was there, what was going on.',
                  child: _Field(
                    controller: _situation,
                    hint: 'e.g. Presenting the update in the team meeting',
                    lines: 4,
                  ),
                ),
                _Step(
                  title: 'What went through your mind?',
                  subtitle:
                      'The thought as it arrived, in your own words. Not a '
                      'tidied-up version — the wording is what we are going '
                      'to look at.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        controller: _thought,
                        hint: 'e.g. I humiliated myself and everyone noticed',
                        lines: 3,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      const _Label('What did it make you feel?'),
                      const SizedBox(height: 8),
                      _Field(
                        controller: _emotion,
                        hint: 'e.g. Embarrassed',
                        lines: 1,
                      ),
                      const SizedBox(height: 20),
                      _Intensity(
                        label: 'How strong is that feeling?',
                        value: _before,
                        onChanged: (v) => setState(() => _before = v),
                      ),
                    ],
                  ),
                ),
                _Step(
                  title: 'What supports the thought?',
                  subtitle:
                      'One thing per line, and only things that actually '
                      'happened. Something you can point to.',
                  child: _EvidenceEditor(
                    controllers: _for,
                    hint: 'e.g. I lost my thread for a few seconds',
                    onChanged: () => setState(() {}),
                  ),
                ),
                _Step(
                  title: 'What does not fit it?',
                  subtitle:
                      'Same again — anything that happened that the thought '
                      'does not account for.',
                  child: _EvidenceEditor(
                    controllers: _against,
                    hint: 'e.g. Two people asked follow-up questions',
                    onChanged: () => setState(() {}),
                  ),
                ),
                _Step(
                  title: 'Looking at both sides',
                  subtitle:
                      'Given what you have written, is there another way to '
                      'read the situation? Not a cheerful one — a fair one.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EvidenceColumns(
                        forItems: _texts(_for),
                        againstItems: _texts(_against),
                      ),
                      const SizedBox(height: 20),
                      _Field(
                        controller: _balanced,
                        hint: 'e.g. I stumbled once and the rest went fine',
                        lines: 4,
                      ),
                    ],
                  ),
                ),
                _Step(
                  title: 'How does it feel now?',
                  subtitle:
                      'Rate the same feeling again. It is fine if nothing has '
                      'shifted — that is information too.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Intensity(
                        label: _emotion.text.trim().isEmpty
                            ? 'How strong is the feeling now?'
                            : 'How strong is the ${_emotion.text.trim().toLowerCase()} now?',
                        value: _after,
                        onChanged: (v) => setState(() => _after = v),
                      ),
                      const SizedBox(height: 24),
                      _BeforeAfter(before: _before, after: _after),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: ChiromoButton(
                      label: 'Back',
                      variant: ChiromoButtonVariant.outline,
                      onPressed: _saving ? null : _back,
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ChiromoButton(
                    label: _step == _stepCount - 1 ? 'Save' : 'Continue',
                    isLoading: _saving,
                    onPressed: _canAdvance ? _next : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Only the thought itself is required. Every other step can be passed
  /// through empty: a tool for anxious people that refuses to move on is a
  /// tool people close.
  bool get _canAdvance {
    if (_saving) return false;
    if (_step == 1) return _thought.text.trim().isNotEmpty;
    return true;
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    _save();
  }

  List<String> _texts(List<TextEditingController> controllers) =>
      controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  Future<void> _save() async {
    setState(() => _saving = true);

    final evidence = <Evidence>[
      for (final text in _texts(_for))
        Evidence(side: EvidenceSide.forThought, text: text),
      for (final text in _texts(_against))
        Evidence(side: EvidenceSide.against, text: text),
    ];

    try {
      await ref
          .read(thoughtNotifierProvider.notifier)
          .save(
            recordedAt: DateTime.now(),
            situation: _situation.text.trim(),
            automaticThought: _thought.text.trim(),
            emotion: _emotion.text.trim(),
            emotionBefore: _before,
            emotionAfter: _after,
            balancedThought: _balanced.text.trim(),
            evidence: evidence,
          );

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

/// A field per item, with add and remove.
///
/// Submitting on the keyboard adds the next row, so building a list is typing
/// rather than tapping Add between each — the friction that would otherwise
/// push someone back towards writing one long paragraph.
class _EvidenceEditor extends StatelessWidget {
  final List<TextEditingController> controllers;
  final String hint;
  final VoidCallback onChanged;

  const _EvidenceEditor({
    required this.controllers,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[i],
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      controllers.add(TextEditingController());
                      onChanged();
                    },
                    decoration: InputDecoration(
                      hintText: i == 0 ? hint : null,
                      border: const OutlineInputBorder(),
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    onPressed: () {
                      controllers.removeAt(i).dispose();
                      onChanged();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    color: ChiromoColors.textTertiary,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            controllers.add(TextEditingController());
            onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add another'),
        ),
      ],
    );
  }
}

/// The two sides laid out together, which is the only moment in the exercise
/// where they can be compared directly.
///
/// Deliberately no count, no score, no verdict. Telling someone their thought
/// is seventy percent unsupported would be a clinical judgement the app has no
/// standing to make, and it would be wrong for the patient whose fear is well
/// founded. The columns are shown; the patient draws the conclusion.
class _EvidenceColumns extends StatelessWidget {
  final List<String> forItems;
  final List<String> againstItems;

  const _EvidenceColumns({required this.forItems, required this.againstItems});

  @override
  Widget build(BuildContext context) {
    if (forItems.isEmpty && againstItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Column(
            title: 'Supports it',
            items: forItems,
            tint: ChiromoColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Column(
            title: 'Does not fit',
            items: againstItems,
            tint: ChiromoColors.statusCompleted,
          ),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;

  const _Column({required this.title, required this.items, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: tint,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Nothing noted',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: ChiromoColors.textTertiary,
              ),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  final int before;
  final int after;

  const _BeforeAfter({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$before', style: _big),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward,
              size: 18,
              color: ChiromoColors.textTertiary,
            ),
          ),
          Text('$after', style: _big),
          const Text(
            '  /10',
            style: TextStyle(fontSize: 13, color: ChiromoColors.textTertiary),
          ),
        ],
      ),
    );
  }

  static const _big = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: ChiromoColors.textPrimary,
  );
}

class _Progress extends StatelessWidget {
  final int step;
  final int total;

  const _Progress({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${step + 1} of $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ChiromoColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / total,
              minHeight: 5,
              backgroundColor: ChiromoColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ChiromoColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Step({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: ChiromoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: ChiromoColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int lines;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    this.lines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines + 2,
      maxLength: 2000,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ChiromoColors.textPrimary,
      ),
    );
  }
}

class _Intensity extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Intensity({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Label(label)),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ChiromoColors.primary,
              ),
            ),
            const Text(
              '/10',
              style: TextStyle(fontSize: 12, color: ChiromoColors.textTertiary),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: kEmotionMin.toDouble(),
          max: kEmotionMax.toDouble(),
          divisions: kEmotionMax - kEmotionMin,
          label: '$value',
          activeColor: ChiromoColors.primary,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
