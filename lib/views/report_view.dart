import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/models/report_model.dart';

/// Quality-Bar form for sellers to flag a problem with the app, a buyer, or
/// an order.
///
/// Layout follows the Phase 1 auth template: a max-width 420 form shell with
/// `_FieldLabel` rows, a [Wrap] of single-select reason chips, a multi-line
/// description textarea, and a 52px primary pill submit CTA. On success the
/// form resets and a snackbar confirms the report was sent; the screen then
/// pops back to the previous route (typically the store / settings menu).
class ReportFormView extends StatefulWidget {
  const ReportFormView({super.key});

  @override
  State<ReportFormView> createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<ReportFormView> {
  static const List<String> _reasons = <String>[
    'App bug',
    'Payment issue',
    'Buyer behavior',
    'Listing problem',
    'Account / login',
    'Feature request',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    if (_selectedReason == null) {
      _snack('Please select a reason.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _snack('You need to be signed in to submit a report.');
        return;
      }

      final report = ReportModel(
        userId: user.uid,
        title: _selectedReason!,
        message: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await locator<IUserProfileService>().submitReport(report);

      if (!mounted) return;
      _snack('Report submitted. Thanks for helping us improve.');
      _formKey.currentState!.reset();
      _descriptionController.clear();
      setState(() => _selectedReason = null);
      // Pop back so the user lands on whichever screen launched the form.
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _snack("Couldn't send your report. Please try again.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report a problem',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "What's going on?",
                      style:
                          tt.headlineSmall?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pick a category, add some detail, and we'll take a look.",
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FieldLabel('Reason', color: cs.onSurface),
                    const SizedBox(height: 12),
                    _ReasonChipsField(
                      reasons: _reasons,
                      selected: _selectedReason,
                      enabled: !_isSubmitting,
                      onChanged: (value) {
                        setState(() => _selectedReason = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel('Describe the issue', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      minLines: 5,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText:
                            'Share as much detail as you can — what happened, when, and any order or listing references.',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) {
                          return 'Please describe the issue';
                        }
                        if (value.length < 10) {
                          return 'A few more words would help us help you';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        child: _isSubmitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Submit report',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We review reports during Cebu business hours. Urgent issues? Email support@unshelf.ph.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      );
}

class _ReasonChipsField extends StatelessWidget {
  const _ReasonChipsField({
    required this.reasons,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> reasons;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reasons.map((reason) {
        final isSelected = selected == reason;
        return FilterChip(
          label: Text(reason),
          selected: isSelected,
          onSelected: enabled ? (_) => onChanged(reason) : null,
          showCheckmark: false,
          labelStyle: tt.labelLarge?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: cs.surfaceContainerHighest,
          selectedColor: cs.primary,
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : cs.outline.withValues(alpha: 0.5),
            width: 1,
          ),
          shape: const StadiumBorder(),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
