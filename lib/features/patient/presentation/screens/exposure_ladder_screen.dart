import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../providers/cbt_providers.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class ExposureLadderStep {
  final int stepNumber;
  final String title;
  final String description;
  final int anxietyLevel; // 0-100
  final List<String> copingStrategies;
  final List<String> reflectionQuestions;
  final Duration suggestedDuration;

  ExposureLadderStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.anxietyLevel,
    required this.copingStrategies,
    required this.reflectionQuestions,
    required this.suggestedDuration,
  });
}

// Pre-built templates for common fears
final exposureLadderTemplates = {
  'social_anxiety': {
    'title': 'Social Anxiety - Group Settings',
    'icon': '👥',
    'steps': [
      ExposureLadderStep(
        stepNumber: 1,
        title: 'Imagine the Scenario',
        description:
            'Spend 10 minutes visualizing yourself at a small group gathering (3-4 people) in a familiar place like a friend\'s home.',
        anxietyLevel: 20,
        copingStrategies: [
          'Deep breathing (4-7-8 technique)',
          'Progressive muscle relaxation',
          'Grounding exercise (5-4-3-2-1 technique)',
        ],
        reflectionQuestions: [
          'What physical sensations did you notice?',
          'What worried thoughts came up?',
          'How did your anxiety change over time?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 2,
        title: 'Watch Others in Social Settings',
        description:
            'Watch a video or movie scene of people in casual conversation. Notice how they interact naturally.',
        anxietyLevel: 25,
        copingStrategies: [
          'Self-compassion statements',
          'Focusing on observation rather than judgment',
          'Taking notes on conversation flow',
        ],
        reflectionQuestions: [
          'What did you notice about how people interact?',
          'Did people seem to be judging each other?',
          'How realistic were your fears?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 3,
        title: 'Initiate Text Conversation',
        description:
            'Send a casual text or message to a friend or acquaintance to start a simple conversation.',
        anxietyLevel: 30,
        copingStrategies: [
          'Write multiple drafts',
          'Remind yourself they usually reply positively',
          'Use positive self-talk',
        ],
        reflectionQuestions: [
          'What was your anxious prediction?',
          'What actually happened?',
          'Did your fear match reality?',
        ],
        suggestedDuration: Duration(minutes: 5),
      ),
      ExposureLadderStep(
        stepNumber: 4,
        title: 'Brief One-on-One Interaction',
        description:
            'Have a 5-10 minute face-to-face conversation with one person in a quiet setting (coffee shop, walk, etc.)',
        anxietyLevel: 45,
        copingStrategies: [
          'Have a conversation starter prepared',
          'Ask the other person questions',
          'Remember they\'re probably nervous too',
        ],
        reflectionQuestions: [
          'What positive things did you notice?',
          'Did they seem uncomfortable with you?',
          'What skills did you use successfully?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 5,
        title: 'Small Group Conversation',
        description:
            'Join a conversation with 3-4 people for 15 minutes. You don\'t need to lead, just participate.',
        anxietyLevel: 55,
        copingStrategies: [
          'Active listening',
          'Ask follow-up questions',
          'Share one small comment or story',
        ],
        reflectionQuestions: [
          'Did people reject you?',
          'Did you connect with anyone?',
          'What would you do differently next time?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 6,
        title: 'Speak Up in Group',
        description:
            'Share your opinion or a relevant comment during the group conversation. Doesn\'t need to be long.',
        anxietyLevel: 65,
        copingStrategies: [
          'Remember your thoughts are valid',
          'People usually welcome new perspectives',
          'Start with "I think..." or "In my experience..."',
        ],
        reflectionQuestions: [
          'What was the group\'s reaction?',
          'Did anyone criticize you unfairly?',
          'How did you feel after speaking?',
        ],
        suggestedDuration: Duration(minutes: 20),
      ),
      ExposureLadderStep(
        stepNumber: 7,
        title: 'Attend Social Event',
        description:
            'Attend a casual social gathering (party, event, meetup) for at least 30 minutes. You can use "buddy" system if needed.',
        anxietyLevel: 75,
        copingStrategies: [
          'Arrive early to ease into it',
          'Have an exit plan (but try to stay)',
          'Find a conversation buddy or host',
        ],
        reflectionQuestions: [
          'What was easier than expected?',
          'What was harder?',
          'Would you go to a similar event again?',
        ],
        suggestedDuration: Duration(minutes: 30),
      ),
    ],
  },
  'public_speaking': {
    'title': 'Public Speaking - Presentations',
    'icon': '🎤',
    'steps': [
      ExposureLadderStep(
        stepNumber: 1,
        title: 'Practice Speaking Alone',
        description:
            'Record yourself speaking for 2-3 minutes about a topic you know well. Listen to the recording.',
        anxietyLevel: 25,
        copingStrategies: [
          'Focus on content over delivery',
          'Remember everyone makes "ums" and "ahs"',
          'Practice power pose before recording',
        ],
        reflectionQuestions: [
          'How did your voice sound?',
          'What did you do well?',
          'What\'s one thing to improve?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 2,
        title: 'Speak to a Trusted Person',
        description:
            'Give a 3-minute talk to a trusted friend or family member about any topic.',
        anxietyLevel: 35,
        copingStrategies: [
          'Choose someone supportive',
          'Remember they want you to succeed',
          'You can ask for feedback afterward',
        ],
        reflectionQuestions: [
          'Did they seem bored or engaged?',
          'What feedback did they give?',
          'What would you do differently?',
        ],
        suggestedDuration: Duration(minutes: 5),
      ),
      ExposureLadderStep(
        stepNumber: 3,
        title: 'Speak to Small Group (2-3 people)',
        description:
            'Give a 5-minute presentation about your work, hobby, or area of knowledge to 2-3 people.',
        anxietyLevel: 50,
        copingStrategies: [
          'Use note cards (not full script)',
          'Make eye contact with one person at a time',
          'Pause for breath',
        ],
        reflectionQuestions: [
          'Did you lose your place?',
          'Did anyone ask questions?',
          'How was the interaction after?',
        ],
        suggestedDuration: Duration(minutes: 8),
      ),
      ExposureLadderStep(
        stepNumber: 4,
        title: 'Contribute to Team Meeting',
        description:
            'Speak up at least once in a team or work meeting with 5-10 people. Share an idea or observation.',
        anxietyLevel: 60,
        copingStrategies: [
          'Prepare one point before the meeting',
          'Write it down to refer to',
          'Remember: Most people support good ideas',
        ],
        reflectionQuestions: [
          'Did anyone respond negatively?',
          'Did your point add value?',
          'How did you feel afterward?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 5,
        title: 'Present to Larger Group (10-15 people)',
        description:
            'Give a 5-10 minute presentation or demo to a group of colleagues or classmates.',
        anxietyLevel: 70,
        copingStrategies: [
          'Use visual aids (slides, handouts)',
          'Practice beforehand 2-3 times',
          'Start with a hook or question',
        ],
        reflectionQuestions: [
          'What were your strengths?',
          'What questions were asked?',
          'Would you do this presentation again?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 6,
        title: 'Give Feedback or Disagree',
        description:
            'Respectfully share a different perspective or constructive criticism in a group setting.',
        anxietyLevel: 75,
        copingStrategies: [
          'Use "sandwich" method (positive-feedback-positive)',
          'Lead with curiosity ("Have you considered...")',
          'Separate criticism from the person',
        ],
        reflectionQuestions: [
          'How did people respond?',
          'Did it start healthy discussion?',
          'Did expressing your view matter?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 7,
        title: 'Formal Presentation (15+ people)',
        description:
            'Give a formal presentation to a larger audience (meeting, class, event) with Q&A session.',
        anxietyLevel: 85,
        copingStrategies: [
          'Rehearse extensively',
          'Arrive early to test equipment',
          'Practice Q&A responses',
        ],
        reflectionQuestions: [
          'What made this easier than expected?',
          'What challenging moments did you handle?',
          'Would you present again?',
        ],
        suggestedDuration: Duration(minutes: 20),
      ),
    ],
  },
  'agoraphobia': {
    'title': 'Agoraphobia - Going Out',
    'icon': '🏠',
    'steps': [
      ExposureLadderStep(
        stepNumber: 1,
        title: 'Sit by the Door',
        description:
            'Sit by your front door for 10-15 minutes. Notice what you see, hear, and feel.',
        anxietyLevel: 15,
        copingStrategies: [
          'Grounding techniques',
          'Breathing exercises',
          'Remind yourself: "I\'m safe in my home"',
        ],
        reflectionQuestions: [
          'What sounds did you hear outside?',
          'Did your anxiety increase or decrease?',
          'What helped you stay calm?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 2,
        title: 'Step Outside for 1-2 Minutes',
        description:
            'Step onto your porch or just outside your door for 1-2 minutes. You can go right back in.',
        anxietyLevel: 25,
        copingStrategies: [
          'Have a support person nearby',
          'Set a specific time (morning is often easier)',
          'Focus on the ground or a nearby object',
        ],
        reflectionQuestions: [
          'What sensations did you notice?',
          'Did panic occur or just anxiety?',
          'How quickly did you recover after?',
        ],
        suggestedDuration: Duration(minutes: 3),
      ),
      ExposureLadderStep(
        stepNumber: 3,
        title: 'Walk to the End of Your Block',
        description:
            'Walk to the end of your block or a nearby visible landmark. Walk slowly and notice your surroundings.',
        anxietyLevel: 40,
        copingStrategies: [
          'Walk with a support person if needed',
          'Have your phone for safety',
          'Count steps or practice mindfulness',
        ],
        reflectionQuestions: [
          'What was your anxiety level on a scale of 1-10?',
          'Did you complete the walk?',
          'What surprised you?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 4,
        title: 'Walk Around Your Neighborhood',
        description:
            'Take a 15-20 minute walk around your neighborhood. You can wear headphones if it helps.',
        anxietyLevel: 50,
        copingStrategies: [
          'Listen to music or a podcast',
          'Walk at your own pace',
          'Have an exit plan (know where to sit/rest)',
        ],
        reflectionQuestions: [
          'Did you notice the environment around you?',
          'How did your body feel?',
          'Would you do this walk again tomorrow?',
        ],
        suggestedDuration: Duration(minutes: 20),
      ),
      ExposureLadderStep(
        stepNumber: 5,
        title: 'Go to a Small, Familiar Store',
        description:
            'Visit a nearby convenience store or small shop where you\'ve been before. Spend 5-10 minutes inside.',
        anxietyLevel: 60,
        copingStrategies: [
          'Go during quiet hours',
          'Have a specific item to buy',
          'Stay for a set time only',
        ],
        reflectionQuestions: [
          'Did escape routes feel available?',
          'Did anyone notice your anxiety?',
          'How did the staff treat you?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 6,
        title: 'Go to a Busier Store',
        description:
            'Visit a medium-sized shop or grocery store during moderate hours. Walk around and browse for 15 minutes.',
        anxietyLevel: 70,
        copingStrategies: [
          'Have a list of items to find',
          'Use the cart for stability',
          'Focus on the shopping task',
        ],
        reflectionQuestions: [
          'What escape routes did you notice?',
          'Did crowding affect your anxiety?',
          'Were you able to make a purchase?',
        ],
        suggestedDuration: Duration(minutes: 20),
      ),
      ExposureLadderStep(
        stepNumber: 7,
        title: 'Visit Busier Places',
        description:
            'Go to a mall, busy shopping center, or outdoor market during normal hours. Stay for 30+ minutes.',
        anxietyLevel: 80,
        copingStrategies: [
          'Go with someone if needed',
          'Identify a safe person or staff member',
          'Take breaks in quieter areas',
        ],
        reflectionQuestions: [
          'What was hardest about this situation?',
          'What would you do differently?',
          'How proud are you for completing this?',
        ],
        suggestedDuration: Duration(minutes: 30),
      ),
    ],
  },
  'health_anxiety': {
    'title': 'Health Anxiety - Body Sensations',
    'icon': '🩺',
    'steps': [
      ExposureLadderStep(
        stepNumber: 1,
        title: 'Notice Body Sensations Mindfully',
        description:
            'Spend 10 minutes in a quiet place and notice your body sensations without judgment (breathing, heartbeat, sensations).',
        anxietyLevel: 20,
        copingStrategies: [
          'Remind yourself: "Sensations are normal"',
          'Count physical sensations instead of interpreting them',
          'Practice curiosity instead of fear',
        ],
        reflectionQuestions: [
          'How many sensations did you notice?',
          'Did your anxiety increase as you focused?',
          'Can you see normal sensations as neutral?',
        ],
        suggestedDuration: Duration(minutes: 10),
      ),
      ExposureLadderStep(
        stepNumber: 2,
        title: 'Skip a Symptom Check',
        description:
            'For one day, resist the urge to check your body for symptoms. Track your anxiety without checking.',
        anxietyLevel: 35,
        copingStrategies: [
          'Keep your hands busy',
          'Practice mindfulness',
          'Delay checking for 10 minutes at a time',
        ],
        reflectionQuestions: [
          'What happened when you didn\'t check?',
          'Did your anxiety increase or decrease?',
          'Can you trust your body?',
        ],
        suggestedDuration: Duration(minutes: 1440), // 1 day
      ),
      ExposureLadderStep(
        stepNumber: 3,
        title: 'Exercise to Trigger Sensations',
        description:
            'Do 10-15 minutes of gentle exercise (walk, yoga, dancing). Notice heart rate and breathing increases.',
        anxietyLevel: 45,
        copingStrategies: [
          'Remind yourself: "This is normal exercise response"',
          'Focus on how good movement feels',
          'Remind yourself: "I\'m safe"',
        ],
        reflectionQuestions: [
          'What sensations did you feel?',
          'Were they the same as your anxiety symptoms?',
          'Did these sensations harm you?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 4,
        title: 'Intentionally Trigger Symptoms',
        description:
            'Deliberately trigger body sensations that worry you (drink caffeine, spin around, hold breath) and observe.',
        anxietyLevel: 55,
        copingStrategies: [
          'In a safe environment',
          'Know what to expect',
          'Use coping skills while observing',
        ],
        reflectionQuestions: [
          'Did the sensation actually happen?',
          'Did it cause harm?',
          'Did it pass like other sensations?',
        ],
        suggestedDuration: Duration(minutes: 15),
      ),
      ExposureLadderStep(
        stepNumber: 5,
        title: 'Delay Medical Reassurance',
        description:
            'When worried about a symptom, delay seeking reassurance or checking for 24 hours. Use coping skills instead.',
        anxietyLevel: 65,
        copingStrategies: [
          'Write down the worry and date it',
          'Practice thought challenging',
          'Do a healthy behavior instead',
        ],
        reflectionQuestions: [
          'Did delaying change your worry?',
          'What happened after 24 hours?',
          'Can you trust your mind?',
        ],
        suggestedDuration: Duration(minutes: 1440),
      ),
      ExposureLadderStep(
        stepNumber: 6,
        title: 'Stop Health Researching',
        description:
            'For one week, don\'t research your symptoms online. Notice the urge without acting on it.',
        anxietyLevel: 70,
        copingStrategies: [
          'Delete medical apps if possible',
          'Tell someone about the goal',
          'Have a replacement activity ready',
        ],
        reflectionQuestions: [
          'How strong was the urge to research?',
          'Did stopping help or hurt your anxiety?',
          'Can you manage not knowing?',
        ],
        suggestedDuration: Duration(days: 7),
      ),
      ExposureLadderStep(
        stepNumber: 7,
        title: 'Live Without Reassurance',
        description:
            'For two weeks, rely on your doctor only (not online searches, friends, or self-checks). Live normally.',
        anxietyLevel: 80,
        copingStrategies: [
          'Trust your regular doctor',
          'Build confidence in your ability to manage',
          'Practice self-trust',
        ],
        reflectionQuestions: [
          'How did your anxiety change?',
          'Did you survive without constant checking?',
          'What did you learn about yourself?',
        ],
        suggestedDuration: Duration(days: 14),
      ),
    ],
  },
};

class ExposureLadderScreen extends ConsumerStatefulWidget {
  const ExposureLadderScreen({super.key});

  @override
  ConsumerState<ExposureLadderScreen> createState() =>
      _ExposureLadderScreenState();
}

class _ExposureLadderScreenState extends ConsumerState<ExposureLadderScreen> {
  final _fearCtrl = TextEditingController();
  String? _selectedTemplate;
  double _currentStep = 0;
  bool _isShared = false;
  bool _isSaving = false;
  // Track reflection answers: stepNumber -> {question -> answer}
  final Map<int, Map<String, TextEditingController>> _reflectionControllers =
      {};
  final Map<int, Map<String, String>> _reflectionAnswers = {};

  @override
  void dispose() {
    _fearCtrl.dispose();
    // Dispose all reflection question controllers
    for (final stepControllers in _reflectionControllers.values) {
      for (final controller in stepControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedTemplate == null) {
      return _buildTemplateSelection(theme);
    }

    final template = exposureLadderTemplates[_selectedTemplate]!;
    final steps = template['steps'] as List<ExposureLadderStep>;

    return AppScaffold(
      title: 'Exposure Ladder',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    template['icon'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete steps at your own pace',
                          style: TextStyle(
                            fontSize: 13,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedTemplate = null),
                    child: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChiromoColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_currentStep.round()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ChiromoColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Step', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: ChiromoColors.primary.withValues(alpha: 0.2),
                  ),
                  Column(
                    children: [
                      Text(
                        '${steps.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ChiromoColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Total', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Steps List
            Text(
              'Your Exposure Hierarchy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep.toInt();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStepCard(step, isCompleted, isCurrent, theme),
              );
            }),

            const SizedBox(height: 24),

            // Share & Save
            SwitchListTile(
              title: const Text('Share with your therapist'),
              subtitle: const Text('They can provide guidance on each step'),
              value: _isShared,
              onChanged: (v) => setState(() => _isShared = v),
              activeThumbColor: ChiromoColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: ChiromoColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Ladder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelection(ThemeData theme) {
    return AppScaffold(
      title: 'Exposure Ladder',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exposure Ladder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Face your fears gradually with proven exposure therapy steps. Choose your situation below or create a custom ladder.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Choose a Template',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            ...exposureLadderTemplates.entries.map((entry) {
              final templateKey = entry.key;
              final template = entry.value;
              final steps = template['steps'] as List<ExposureLadderStep>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedTemplate = templateKey),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ChiromoColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Text(
                            template['icon'] as String,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${steps.length} proven steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChiromoColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: ChiromoColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            Text(
              'Create Custom Ladder',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _fearCtrl,
              label: 'Your Fear or Avoided Situation',
              hint: 'e.g., Driving on highways, being in crowded places, etc.',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _fearCtrl.text.isEmpty ? null : _createCustomLadder,
                style: FilledButton.styleFrom(
                  backgroundColor: ChiromoColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create Custom Ladder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    ExposureLadderStep step,
    bool isCompleted,
    bool isCurrent,
    ThemeData theme,
  ) {
    final anxietyColor = _getAnxietyColor(step.anxietyLevel);

    return GestureDetector(
      onTap: isCurrent ? () => _showStepDetails(step) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrent
                ? ChiromoColors.primary
                : (isCompleted
                      ? Colors.green
                      : ChiromoColors.primary.withValues(alpha: 0.2)),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.05)
              : (isCurrent
                    ? ChiromoColors.primary.withValues(alpha: 0.08)
                    : Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : anxietyColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${step.stepNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: anxietyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Anxiety Level: ${step.anxietyLevel}/100',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: anxietyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ChiromoColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: ChiromoColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${step.suggestedDuration.inMinutes} min${step.suggestedDuration.inDays > 0 ? ' per day' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStepDetails(ExposureLadderStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ChiromoColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Step ${step.stepNumber}: ${step.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Anxiety Level
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAnxietyColor(
                    step.anxietyLevel,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Anxiety Level',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: step.anxietyLevel / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          _getAnxietyColor(step.anxietyLevel),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${step.anxietyLevel}/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getAnxietyColor(step.anxietyLevel),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'What to Do',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Coping Strategies
              Text(
                'Coping Strategies',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...step.copingStrategies.map(
                (strategy) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strategy,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Reflection Questions - Answerable
              Text(
                'Reflection Questions',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...step.reflectionQuestions.map((question) {
                // Initialize controllers for this step if needed
                _reflectionControllers.putIfAbsent(step.stepNumber, () => {});
                if (!_reflectionControllers[step.stepNumber]!.containsKey(
                  question,
                )) {
                  _reflectionControllers[step.stepNumber]![question] =
                      TextEditingController();
                }
                final controller =
                    _reflectionControllers[step.stepNumber]![question]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: ChiromoColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        onChanged: (value) {
                          setState(() {
                            _reflectionAnswers.putIfAbsent(
                              step.stepNumber,
                              () => {},
                            );
                            _reflectionAnswers[step.stepNumber]![question] =
                                value;
                          });
                        },
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write your reflection here...',
                          hintStyle: TextStyle(
                            color: ChiromoColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: ChiromoColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Duration
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: ChiromoColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested Duration: ${step.suggestedDuration.inMinutes} minutes',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mark as complete
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      if (_currentStep < step.stepNumber) {
                        _currentStep = step.stepNumber.toDouble();
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mark as Complete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAnxietyColor(int level) {
    if (level < 30) return Colors.green;
    if (level < 60) return Colors.orange;
    return Colors.red;
  }

  void _createCustomLadder() {
    setState(() {
      _selectedTemplate = 'custom';
      _fearCtrl.clear();
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ChiromoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: ChiromoColors.textTertiary),
            filled: true,
            fillColor: ChiromoColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'This field is required' : null,
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final template = exposureLadderTemplates[_selectedTemplate];
    final stepsList = template?['steps'] as List<ExposureLadderStep>? ?? [];

    // Build steps with answers included
    final stepsWithAnswers = stepsList
        .map(
          (s) => {
            'stepNumber': s.stepNumber,
            'title': s.title,
            'description': s.description,
            'anxietyLevel': s.anxietyLevel,
            'copingStrategies': s.copingStrategies,
            'reflectionQuestions': s.reflectionQuestions,
            // Include user's answers to reflection questions
            'reflectionAnswers': _reflectionAnswers[s.stepNumber] ?? {},
            'answeredQuestionsCount':
                (_reflectionAnswers[s.stepNumber] ?? {}).length,
          },
        )
        .toList();

    final exercise = CbtExerciseEntity(
      id: '',
      patientId: user.id,
      type: CbtExerciseType.exposureLadder,
      title: _fearCtrl.text.isNotEmpty
          ? _fearCtrl.text
          : (template?['title'] as String? ?? 'Exposure Ladder'),
      data: {
        'template': _selectedTemplate,
        'fear': _fearCtrl.text,
        'current_step': _currentStep.round(),
        'total_steps': stepsList.length,
        'completedAt': DateTime.now().toIso8601String(),
        'steps': stepsWithAnswers,
        // Summary of answers provided
        'totalReflectionQuestions': stepsList.fold<int>(
          0,
          (sum, s) => sum + s.reflectionQuestions.length,
        ),
        'questionsAnswered': _reflectionAnswers.values.fold<int>(
          0,
          (sum, answers) => sum + answers.length,
        ),
      },
      isShared: _isShared,
      hasDoctorFeedback: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(cbtRepositoryProvider);
      await repo.createExercise(exercise);
      ref.invalidate(cbtExercisesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ladder saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
