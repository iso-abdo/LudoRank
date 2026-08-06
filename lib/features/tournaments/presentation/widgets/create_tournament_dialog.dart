import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';
import 'package:ludo_rank/features/tournaments/presentation/providers/tournament_provider.dart';

class CreateTournamentDialog extends StatefulWidget {
  const CreateTournamentDialog({super.key});

  @override
  State<CreateTournamentDialog> createState() =>
      _CreateTournamentDialogState();
}

class _CreateTournamentDialogState
    extends State<CreateTournamentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  int _rounds = 5;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tournament = Tournament(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      status: TournamentStatus.draft,
      rounds: _rounds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context
        .read<TournamentProvider>()
        .addTournament(tournament);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("إنشاء بطولة"),

      content: Form(
        key: _formKey,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "اسم البطولة",
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "أدخل اسم البطولة";
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _rounds,

              decoration: const InputDecoration(
                labelText: "عدد الجولات",
              ),

              items: const [
                DropdownMenuItem(value: 1, child: Text("1")),
                DropdownMenuItem(value: 2, child: Text("2")),
                DropdownMenuItem(value: 3, child: Text("3")),
                DropdownMenuItem(value: 4, child: Text("4")),
                DropdownMenuItem(value: 5, child: Text("5")),
                DropdownMenuItem(value: 6, child: Text("6")),
                DropdownMenuItem(value: 7, child: Text("7")),
                DropdownMenuItem(value: 8, child: Text("8")),
                DropdownMenuItem(value: 9, child: Text("9")),
                DropdownMenuItem(value: 10, child: Text("10")),
              ],

              onChanged: (value) {
                setState(() {
                  _rounds = value!;
                });
              },
            ),

          ],
        ),
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),

        FilledButton(
          onPressed: _save,
          child: const Text("إنشاء"),
        ),

      ],
    );
  }
}