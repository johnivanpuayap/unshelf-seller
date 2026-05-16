import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/viewmodels/store_schedule_viewmodel.dart';

/// Edit Store Schedule screen.
///
/// One card per day (Mon–Sun) with an "open" toggle. When a day is open, two
/// time-picker chips expose opens-at / closes-at; tapping each opens a themed
/// `showTimePicker`. Bottom 52px pill commits via `saveProfile`.
class EditStoreScheduleView extends ConsumerStatefulWidget {
  final StoreModel storeDetails;

  const EditStoreScheduleView({super.key, required this.storeDetails});

  @override
  ConsumerState<EditStoreScheduleView> createState() =>
      _EditStoreScheduleViewState();
}

class _EditStoreScheduleViewState extends ConsumerState<EditStoreScheduleView> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storeScheduleViewModelProvider.notifier)
          .loadFromStore(widget.storeDetails);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final notifier = ref.read(storeScheduleViewModelProvider.notifier);
    final saved =
        await notifier.saveProfile(context, widget.storeDetails.userId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeScheduleViewModelProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final days = state.storeSchedule.keys.toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store schedule',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set the days and hours when buyers can place orders for pickup.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < days.length; i++) ...[
                          _DayCard(
                            day: days[i],
                            isOpen: state.storeSchedule[days[i]]!['isOpen']
                                    as bool? ??
                                false,
                            openLabel:
                                (state.storeSchedule[days[i]]!['open'] ?? '')
                                    .toString(),
                            closeLabel:
                                (state.storeSchedule[days[i]]!['close'] ?? '')
                                    .toString(),
                          ),
                          if (i < days.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving || days.isEmpty ? null : _save,
                      child: _saving
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(
                              'Save schedule',
                              style: tt.labelLarge
                                  ?.copyWith(color: cs.onPrimary),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Day card — toggle on the header, time picker chips when open
// ────────────────────────────────────────────────────────────────────────────

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.isOpen,
    required this.openLabel,
    required this.closeLabel,
  });

  final String day;
  final bool isOpen;
  final String openLabel;
  final String closeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final notifier = ref.read(storeScheduleViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1F2A20).withValues(alpha: .06),
            offset: const Offset(0, 8),
            blurRadius: 28,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              Text(
                isOpen ? 'Open' : 'Closed',
                style: tt.labelMedium?.copyWith(
                  color: isOpen
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: isOpen,
                onChanged: (_) => notifier.toggleDay(day),
              ),
            ],
          ),
          if (isOpen) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: 'Opens',
                      value: openLabel,
                      onTap: () => _pickTime(context, notifier, 'open'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeChip(
                      label: 'Closes',
                      value: closeLabel,
                      onTap: () => _pickTime(context, notifier, 'close'),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Closed all day',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    StoreScheduleViewModel notifier,
    String type,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) {
        // Theme inherits from the app's `ThemeData`, so the picker already
        // honours the primary colour. The builder just keeps Material 3 on.
        return Theme(data: Theme.of(ctx), child: child ?? const SizedBox());
      },
    );
    if (picked != null) {
      await notifier.selectTime(day, type, picked);
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Time chip — Quality-Bar styled tappable surface
// ────────────────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final hasValue = value.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasValue ? value : 'Set time',
                style: tt.titleSmall?.copyWith(
                  color: hasValue
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
