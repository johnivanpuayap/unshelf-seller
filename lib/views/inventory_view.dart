import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/viewmodels/inventory_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/views/batch_history_view.dart';
import 'package:intl/intl.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryViewModelProvider.notifier).fetchInventory();
      filteredItems = ref.read(inventoryViewModelProvider).inventoryItems;
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final items = ref.read(inventoryViewModelProvider).inventoryItems;
    setState(() {
      filteredItems = items
          .where((item) => item.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryState = ref.watch(inventoryViewModelProvider);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Store Inventory',
          onBackPressed: () {
            ref.read(inventoryViewModelProvider.notifier).clearData();
            Navigator.pop(context);
          }),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Loading or Inventory List
          Expanded(
            child: inventoryState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No inventory items',
                        subtitle: 'Add products to see them here.',
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            child: ExpansionTile(
                              leading: const Icon(Icons.inventory_2,
                                  color: AppColors.primaryColor),
                              title: Text(
                                item.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              children: [
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing12,
                                    vertical: AppTheme.spacing8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch Details:',
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacing8),
                                      if (item.batches.isEmpty) ...[
                                        Text(
                                          'No batches available',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ] else ...[
                                        Column(
                                          children:
                                              item.batches.map<Widget>((batch) {
                                            return GestureDetector(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          BatchHistoryView(
                                                              batchId: batch
                                                                  .batchNumber)),
                                                );
                                              },
                                              child: ListTile(
                                                contentPadding:
                                                    EdgeInsets.zero,
                                                leading: const Icon(
                                                  Icons.check_circle_outline,
                                                  color: AppColors.lightColor,
                                                ),
                                                title: Text(
                                                  'Batch: ${batch.batchNumber}',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Stock: ${batch.stock} | Expiry: ${DateFormat('MMMM d, y h:mm a').format(batch.expiryDate)}',
                                                  style: theme
                                                      .textTheme.bodySmall,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
