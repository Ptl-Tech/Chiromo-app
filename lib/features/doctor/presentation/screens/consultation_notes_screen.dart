import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class ConsultationNotesScreen extends StatefulWidget {
  const ConsultationNotesScreen({super.key});

  @override
  State<ConsultationNotesScreen> createState() =>
      _ConsultationNotesScreenState();
}

class _ConsultationNotesScreenState extends State<ConsultationNotesScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Consultation Notes',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChiromoColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: ChiromoColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Doe',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Male, 34 yrs | ID: P-2394',
                        style: TextStyle(
                          color: ChiromoColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Clinical Notes',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _notesCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText:
                      'Enter subjective, objective, assessment, and plan (SOAP)...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ChiromoColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ChiromoButton(
              label: 'Submit & Sign Notes',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes saved successfully')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
