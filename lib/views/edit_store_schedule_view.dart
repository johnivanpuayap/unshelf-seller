import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/store_schedule_viewmodel.dart';

class EditStoreScheduleView extends ConsumerStatefulWidget {
  final StoreModel storeDetails;

  const EditStoreScheduleView({super.key, required this.storeDetails});

  @override
  ConsumerState<EditStoreScheduleView> createState() =>
      _EditStoreScheduleViewState();
}

class _EditStoreScheduleViewState extends ConsumerState<EditStoreScheduleView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storeScheduleViewModelProvider.notifier)
          .loadFromStore(widget.storeDetails);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(storeScheduleViewModelProvider);
    final notifier = ref.read(storeScheduleViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Store Schedule',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: viewModel.storeSchedule.keys.map((day) {
                  bool isActive = viewModel.storeSchedule[day]!['isOpen'];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing8),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(day,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              Switch(
                                value: isActive,
                                activeThumbColor: AppColors.primaryColor,
                                onChanged: (value) =>
                                    notifier.toggleDay(day),
                              ),
                            ],
                          ),
                          if (isActive) ...[
                            const SizedBox(height: AppTheme.spacing8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _TimePickerButton(
                                  label: 'Opening Time',
                                  time: viewModel
                                      .storeSchedule[day]!['open']!,
                                  onPressed: () async {
                                    final TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      notifier.selectTime(
                                          day, 'open', pickedTime);
                                    }
                                  },
                                ),
                                _TimePickerButton(
                                  label: 'Closing Time',
                                  time: viewModel
                                      .storeSchedule[day]!['close']!,
                                  onPressed: () async {
                                    final TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      notifier.selectTime(
                                          day, 'close', pickedTime);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              'Closed all day',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            CustomButton(
                text: 'Save Changes',
                onPressed: () async {
                  bool isSaved = await notifier.saveProfile(
                      context, widget.storeDetails.userId);

                  if (isSaved && context.mounted) {
                    Navigator.pop(context);
                  }
                }),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onPressed;

  const _TimePickerButton(
      {required this.label, required this.time, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacing4),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(time.isEmpty ? 'Set Time' : time),
        ),
      ],
    );
  }
}
