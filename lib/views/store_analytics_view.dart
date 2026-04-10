import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/analytics_viewmodel.dart';
import 'package:unshelf_seller/components/chart.dart';

class StoreAnalyticsView extends StatefulWidget {
  const StoreAnalyticsView({super.key});

  @override
  State<StoreAnalyticsView> createState() => _StoreAnalyticsViewState();
}

class _StoreAnalyticsViewState extends State<StoreAnalyticsView> {
  String selectedSalesValue = 'Daily';
  String selectedOrdersValue = 'Daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsViewModel =
          Provider.of<AnalyticsViewModel>(context, listen: false);

      analyticsViewModel.fetchAnalyticsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Store Analytics',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Consumer<AnalyticsViewModel>(
        builder: (context, analyticsViewModel, _) {
          return analyticsViewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lifetime Totals Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lifetime Totals',
                                style: theme.textTheme.headlineLarge,
                              ),
                              const SizedBox(height: AppTheme.spacing16),

                              // Centered Total Orders
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Total Orders',
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    Text(
                                      '${analyticsViewModel.totalOrders}',
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    // Order Status Breakdown in one row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildOrderStatColumn(
                                          context,
                                          'Pending',
                                          '${analyticsViewModel.totalPendingOrders}',
                                        ),
                                        _buildOrderStatColumn(
                                          context,
                                          'Ready',
                                          '${analyticsViewModel.totalReadyOrders}',
                                        ),
                                        _buildOrderStatColumn(
                                          context,
                                          'Completed',
                                          '${analyticsViewModel.totalCompletedOrders}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacing16),

                              // Centered Total Sales
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Total Sales',
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    Text(
                                      '\u20B1 ${analyticsViewModel.totalSales.toStringAsFixed(2)}',
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing24),
                      Text(
                        'Orders',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      DropdownButton<String>(
                        value: selectedOrdersValue,
                        onChanged: (String? newValue) {
                          if (newValue != null &&
                              newValue != selectedOrdersValue) {
                            setState(() {
                              selectedOrdersValue = newValue;
                            });
                          }
                        },
                        items: <String>['Daily', 'Weekly', 'Monthly', 'Annual']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),

                      if (selectedOrdersValue == 'Daily' &&
                          analyticsViewModel.dailyOrdersMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.dailyOrdersMap,
                          maxXValue: 14,
                          maxYValue: analyticsViewModel.dailyMaxYOrder,
                        )
                      else if (selectedOrdersValue == 'Weekly' &&
                          analyticsViewModel.weeklyOrdersMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.weeklyOrdersMap,
                          maxXValue: 4,
                          maxYValue: analyticsViewModel.weeklyMaxYOrder,
                        )
                      else if (selectedOrdersValue == 'Monthly' &&
                          analyticsViewModel.monthlyOrdersMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.monthlyOrdersMap,
                          maxXValue: 6,
                          maxYValue: analyticsViewModel.monthlyMaxYOrder,
                        )
                      else if (selectedOrdersValue == 'Annual' &&
                          analyticsViewModel.annualOrdersMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.annualOrdersMap,
                          maxXValue: 3,
                          maxYValue: analyticsViewModel.annualMaxYOrder,
                        ),

                      const SizedBox(height: AppTheme.spacing32),
                      Text(
                        'Sales',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacing12),

                      DropdownButton<String>(
                        value: selectedSalesValue,
                        onChanged: (String? newValue) {
                          if (newValue != null &&
                              newValue != selectedSalesValue) {
                            setState(() {
                              selectedSalesValue = newValue;
                            });
                          }
                        },
                        items: <String>['Daily', 'Weekly', 'Monthly', 'Annual']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),

                      if (selectedSalesValue == 'Daily' &&
                          analyticsViewModel.dailySalesMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.dailySalesMap,
                          maxXValue: 14,
                          maxYValue: analyticsViewModel.dailyMaxYSales,
                        )
                      else if (selectedSalesValue == 'Weekly' &&
                          analyticsViewModel.weeklySalesMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.weeklySalesMap,
                          maxXValue: 4,
                          maxYValue: analyticsViewModel.weeklyMaxYSales,
                        )
                      else if (selectedSalesValue == 'Monthly' &&
                          analyticsViewModel.monthlySalesMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.monthlySalesMap,
                          maxXValue: 6,
                          maxYValue: analyticsViewModel.monthlyMaxYSales,
                        )
                      else if (selectedSalesValue == 'Annual' &&
                          analyticsViewModel.annualSalesMap.isNotEmpty)
                        Chart(
                          dataMap: analyticsViewModel.annualSalesMap,
                          maxXValue: 3,
                          maxYValue: analyticsViewModel.annualMaxYSales,
                        ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildOrderStatColumn(
      BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
