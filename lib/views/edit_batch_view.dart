import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/viewmodels/batch_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class EditBatchView extends ConsumerStatefulWidget {
  final String batchNumber;

  const EditBatchView({super.key, required this.batchNumber});

  @override
  ConsumerState<EditBatchView> createState() => _EditBatchViewState();
}

class _EditBatchViewState extends ConsumerState<EditBatchView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(batchViewModelProvider.notifier)
          .fetchBatch(widget.batchNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchViewModelProvider);
    final notifier = ref.read(batchViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Batch Details',
          onBackPressed: () {
            notifier.clearData();
            Navigator.pop(context);
          }),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    child: Text(
                      'Batch Number: ${state.batchNumber}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryColor,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Expiry Date'),
                    readOnly: true,
                    controller: notifier.expiryDateController,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        final formattedDate =
                            DateFormat('MM-dd-yyyy').format(date);
                        notifier.expiryDateController.text = formattedDate;
                        notifier.expiryDate = date;
                        if (context.mounted) FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        notifier.price = double.tryParse(value),
                    controller: notifier.priceController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => notifier.stock = int.tryParse(value),
                    controller: notifier.stockController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantifier'),
                    onChanged: (value) => notifier.quantifier = value,
                    controller: notifier.quantifierController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Discount (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        notifier.discount = int.tryParse(value),
                    controller: notifier.discountController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  CustomButton(
                    text: 'Update Product Batch',
                    onPressed: () async {
                      await notifier.updateBatch();
                      if (!ref.read(batchViewModelProvider).isLoading) {
                        notifier.clearData();
                        if (context.mounted) Navigator.pop(context, true);
                      }
                    },
                  )
                ],
              ),
            ),
    );
  }
}
