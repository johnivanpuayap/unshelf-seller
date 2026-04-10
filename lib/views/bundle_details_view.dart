import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class BundleDetailsView extends StatefulWidget {
  final String bundleId;

  const BundleDetailsView({super.key, required this.bundleId});

  @override
  State<BundleDetailsView> createState() => _BundleDetailsViewState();
}

class _BundleDetailsViewState extends State<BundleDetailsView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<BundleViewModel>().getBundleDetails(widget.bundleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Bundle Details',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Consumer<BundleViewModel>(
        builder: (context, viewModel, child) {
          final BundleModel? bundle = viewModel.bundle;

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bundle == null) {
            return const Center(child: Text('Bundle not found.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bundle Image
                  Center(
                    child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        child: Image.network(
                          bundle.mainImageUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  // Name and Description
                  _buildDetailCard(context, 'Name', bundle.name),
                  _buildDetailCard(context, 'Description', bundle.description),
                  _buildDetailCard(context, 'Category', bundle.category),
                  _buildDetailCard(context, 'Price', bundle.price.toString()),
                  _buildDetailCard(context, 'Stock', bundle.stock.toString()),
                  _buildDetailCard(
                      context, 'Discount', '${bundle.discount}%'),

                  // Product List
                  const SizedBox(height: AppTheme.spacing8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    child: Text(
                      'Products',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.primaryColor),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing8),
                  ...bundle.items.map((item) {
                    return Card(
                      elevation: AppTheme.elevationMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            image: item['imageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        item['imageUrl'].toString()),
                                    fit: BoxFit.cover)
                                : null,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall / 4),
                          ),
                        ),
                        title: Text(
                          item['name'].toString(),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'x ${item['quantity']} ${item['quantifier']}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppTheme.spacing24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      elevation: AppTheme.elevationMedium,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            if (title != 'Price')
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              Expanded(
                flex: 2,
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textPrimary),
                    children: [
                      const TextSpan(
                        text: '\u20B1 ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                        ),
                      ),
                      TextSpan(
                        text: value,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
