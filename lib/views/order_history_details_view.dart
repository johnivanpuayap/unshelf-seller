import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:intl/intl.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/batch_model.dart';

class OrderHistoryDetailsView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderHistoryDetailsView({super.key, required this.orderId});

  @override
  ConsumerState<OrderHistoryDetailsView> createState() =>
      _OrderHistoryDetailsViewState();
}

class _OrderHistoryDetailsViewState
    extends ConsumerState<OrderHistoryDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderViewModelProvider.notifier).selectOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(orderViewModelProvider);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Order History Details',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacing12),
                    Text(
                      'Order ID: ${state.selectedOrder!.orderId}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildDetailCard(
                        context, 'Buyer Name', state.selectedOrder!.buyerName),
                    _buildDetailCard(
                        context,
                        'Order Date',
                        DateFormat('MMMM dd, yyyy hh:mm a')
                            .format(state.selectedOrder!.createdAt.toDate())),

                    if (!state.selectedOrder!.isPaid) ...[
                      _buildDetailCard(context, 'Payment Mode', 'Cash'),
                    ] else ...[
                      _buildDetailCard(context, 'Payment Mode', 'Paid Online'),
                    ],

                    _buildDetailCard(context, 'Subtotal',
                        state.selectedOrder!.subtotal.toStringAsFixed(2)),
                    _buildDetailCard(context, 'Discount',
                        state.selectedOrder!.pointsDiscount.toString()),
                    _buildDetailCard(context, 'Total Price',
                        state.selectedOrder!.totalPrice.toStringAsFixed(2)),
                    _buildDetailCard(
                        context, 'Status', state.selectedOrder!.status),
                    const SizedBox(height: AppTheme.spacing8),

                    _buildDetailCard(
                        context,
                        'Pickup Time',
                        DateFormat('MMMM dd, yyyy hh:mm a')
                            .format(state.selectedOrder!.pickupTime!.toDate())),

                    if (state.currentStatus == 'Cancelled') ...[
                      _buildDetailCard(
                          context,
                          'Cancelled At',
                          DateFormat('MMMM dd, yyyy hh:mm a').format(
                              state.selectedOrder!.cancelledAt!.toDate())),
                    ],

                    if (state.selectedOrder!.status == 'Ready' ||
                        state.selectedOrder!.status == 'Completed') ...[
                      _buildDetailCard(context, 'Pickup Code',
                          state.selectedOrder!.pickupCode!),
                    ],

                    if (state.selectedOrder!.status == 'Completed') ...[
                      _buildDetailCard(
                          context,
                          'Completed At',
                          DateFormat('MMMM dd, yyyy hh:mm a').format(
                              state.selectedOrder!.completedAt!.toDate())),
                    ],

                    const SizedBox(height: AppTheme.spacing12),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing8),
                      child: SectionHeader(
                        title: 'Items in Order',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),

                    ListView.builder(
                      itemCount: state.selectedOrder!.items.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = state.selectedOrder!.items[index];
                        Widget? leadingImage;
                        BundleModel? bundle;
                        BatchModel? product;

                        if (item.isBundle ?? false) {
                          bundle =
                              state.selectedOrder!.bundles!.firstWhere(
                            (bundle) => bundle.id == item.batchId,
                          );
                          leadingImage = bundle.mainImageUrl.isNotEmpty
                              ? Image.network(
                                  bundle.mainImageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/placeholder.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                );
                        } else {
                          product = state.selectedOrder!.products!.firstWhere(
                              (product) =>
                                  product.batchNumber == item.batchId);

                          leadingImage =
                              product.product!.mainImageUrl.isNotEmpty
                                  ? Image.network(
                                      product.product!.mainImageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/placeholder.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                        }

                        return Card(
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(
                                      AppTheme.radiusMedium)),
                              child: leadingImage,
                            ),
                            title: Text(
                              item.isBundle ?? false
                                  ? bundle!.name
                                  : product!.product!.name,
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'x ${item.quantity} ${item.isBundle ?? false ? '' : product!.quantifier}',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '₱ ${item.price!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (title == 'Pending Payment') ...[
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              )
            ] else ...[
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
