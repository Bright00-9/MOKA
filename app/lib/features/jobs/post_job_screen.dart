import 'package:flutter/material.dart';
import '../../core/services/jobs_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  int? _requiredStarLevel;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await JobsService.createJob(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        location: _locationController.text.trim(),
        budgetMin: int.tryParse(_budgetMinController.text),
        budgetMax: int.tryParse(_budgetMaxController.text),
        requiredStarLevel: _requiredStarLevel,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Could not post the job. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a job')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 5) ? 'At least 5 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 20) ? 'At least 20 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration:
                    const InputDecoration(labelText: 'Category (e.g. Plumbing)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Budget min (GHS)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Budget max (GHS)', border: OutlineInputBorder()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _requiredStarLevel,
                decoration: const InputDecoration(
                  labelText: 'Minimum provider star tier (optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Leave blank to accept applications from any tier',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any tier')),
                  ...List.generate(5, (i) => i + 1)
                      .map((s) => DropdownMenuItem(value: s, child: Text('Tier $s and above'))),
                ],
                onChanged: (v) => setState(() => _requiredStarLevel = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Post job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
