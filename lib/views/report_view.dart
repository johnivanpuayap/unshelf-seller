import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/models/report_model.dart';
import 'package:unshelf_seller/utils/theme.dart';

class ReportFormView extends StatefulWidget {
  @override
  _ReportFormViewState createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<ReportFormView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw Exception('User not logged in');
        }

        final report = ReportModel(
          userId: user.uid,
          title: _titleController.text,
          message: _descriptionController.text,
          createdAt: DateTime.now(),
        );

        await locator<IUserProfileService>().submitReport(report);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully!')),
        );

        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Report Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value!.isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing32,
                          vertical: AppTheme.spacing16),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Submit Report',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
