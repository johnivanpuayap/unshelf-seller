import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/viewmodels/batch_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class EditBatchView extends StatefulWidget {
  final String batchNumber;

  const EditBatchView({super.key, required this.batchNumber});

  @override
  State<EditBatchView> createState() => _EditBatchViewState();
}

class _EditBatchViewState extends State<EditBatchView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BatchViewModel>(context, listen: false)
          .fetchBatch(widget.batchNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<BatchViewModel>(context);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Batch Details',
          onBackPressed: () {
            viewModel.clearData();
            Navigator.pop(context);
          }),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    child: Text(
                      'Batch Number: ${viewModel.batchNumber}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryColor,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Expiry Date'),
                    readOnly: true,
                    controller: viewModel.expiryDateController,
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
                        viewModel.expiryDateController.text = formattedDate;
                        viewModel.expiryDate = date;
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        viewModel.price = double.tryParse(value),
                    controller: viewModel.priceController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => viewModel.stock = int.tryParse(value),
                    controller: viewModel.stockController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantifier'),
                    onChanged: (value) => viewModel.quantifier = value,
                    controller: viewModel.quantifierController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Discount (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        viewModel.discount = int.tryParse(value),
                    controller: viewModel.discountController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  CustomButton(
                    text: 'Update Product Batch',
                    onPressed: () async {
                      await viewModel.updateBatch();
                      if (!viewModel.isLoading) {
                        viewModel.clearData();
                        Navigator.pop(context, true);
                      }
                    },
                  )
                ],
              ),
            ),
    );
  }
}
