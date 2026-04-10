import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/chart.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/product_analytics_viewmodel.dart';

class ProductAnalyticsView extends StatefulWidget {
  const ProductAnalyticsView({super.key});

  @override
  State<ProductAnalyticsView> createState() => _ProductAnalyticsViewState();
}

class _ProductAnalyticsViewState extends State<ProductAnalyticsView> {
  late ProductAnalyticsViewModel viewModel;
  String selectedSalesValue = 'Daily';
  String selectedOrdersValue = 'Daily';
  String selectedProduct = 'Apples';
  Map<String, Map<String, dynamic>> data = {};

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<ProductAnalyticsViewModel>(context, listen: false);
      viewModel.fetchProductAnalytics();
    });

    DateTime today = DateTime.now();

    List<DateTime> generateDateRange(int days) {
      return List.generate(days, (index) {
        return today.subtract(Duration(days: index));
      });
    }

    List<DateTime> generateWeekRange(int weeks) {
      return List.generate(weeks, (index) {
        return today.subtract(Duration(days: (index * 7)));
      });
    }

    List<DateTime> generateMonthRange(int months) {
      return List.generate(months, (index) {
        return DateTime(today.year, today.month - index, today.day);
      });
    }

    List<DateTime> generateYearRange(int years) {
      return List.generate(years, (index) {
        return DateTime(today.year - index, today.month, today.day);
      });
    }

    data = {
      'Apples': {
        'totalOrders': 200,
        'totalSales': 36000.0,
        'totalCancelledOrders': 20,
        'totalCompletedOrders': 180,
        'dailySalesMap': generateDateRange(14).asMap().map((index, date) {
          double dailySales = Random().nextDouble() * 100.0;
          return MapEntry(date, dailySales);
        }),
        'weeklySalesMap': generateWeekRange(4).asMap().map((index, date) {
          double weeklySales = Random().nextDouble() * 500.0;
          return MapEntry(date, weeklySales);
        }),
        'monthlySalesMap': generateMonthRange(6).asMap().map((index, date) {
          double monthlySales = Random().nextDouble() * 1000.0;
          return MapEntry(date, monthlySales);
        }),
        'annualSalesMap': generateYearRange(3).asMap().map((index, date) {
          double annualSales = Random().nextDouble() * 10000.0;
          return MapEntry(date, annualSales);
        }),
      },
      'Watermelon': {
        'totalOrders': 50,
        'totalSales': 12250.0,
        'totalCompletedOrders': 49,
        'totalCancelledOrders': 1,
        'dailySalesMap': generateDateRange(14).asMap().map((index, date) {
          double dailySales = Random().nextDouble() * 200.0;
          return MapEntry(date, dailySales);
        }),
        'weeklySalesMap': generateWeekRange(4).asMap().map((index, date) {
          double weeklySales = Random().nextDouble() * 1000.0;
          return MapEntry(date, weeklySales);
        }),
        'monthlySalesMap': generateMonthRange(6).asMap().map((index, date) {
          double monthlySales = Random().nextDouble() * 2000.0;
          return MapEntry(date, monthlySales);
        }),
        'annualSalesMap': generateYearRange(3).asMap().map((index, date) {
          double annualSales = Random().nextDouble() * 10000.0;
          return MapEntry(date, annualSales);
        }),
      },
      'Purple Grapes': {
        'totalOrders': 100,
        'totalSales': 19000.0,
        'totalCompletedOrders': 95,
        'totalCancelledOrders': 5,
        'dailySalesMap': generateDateRange(14).asMap().map((index, date) {
          double dailySales = Random().nextDouble() * 100.0;
          return MapEntry(date, dailySales);
        }),
        'weeklySalesMap': generateWeekRange(4).asMap().map((index, date) {
          double weeklySales = Random().nextDouble() * 500.0;
          return MapEntry(date, weeklySales);
        }),
        'monthlySalesMap': generateMonthRange(6).asMap().map((index, date) {
          double monthlySales = Random().nextDouble() * 1200.0;
          return MapEntry(date, monthlySales);
        }),
        'annualSalesMap': generateYearRange(3).asMap().map((index, date) {
          double annualSales = Random().nextDouble() * 2500.0;
          return MapEntry(date, annualSales);
        }),
      },
    };
  }

  Map<String, dynamic> get currentProductData {
    return data[selectedProduct]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<ProductAnalyticsViewModel>(context);
    var dataName = data.keys.toList();

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Product Analytics',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedProduct,
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != selectedProduct) {
                            setState(() {
                              selectedProduct = newValue;
                            });
                          }
                        },
                        items: dataName
                            .map<DropdownMenuItem<String>>((var product) {
                          return DropdownMenuItem<String>(
                            value: product,
                            child: Text(
                              product,
                              style: theme.textTheme.titleMedium,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Lifetime Totals Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lifetime Totals',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Total Orders',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  '${currentProductData['totalOrders']}',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacing8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn(
                                      context,
                                      'Completed',
                                      currentProductData[
                                          'totalCompletedOrders'],
                                    ),
                                    _buildStatColumn(
                                      context,
                                      'Cancelled',
                                      currentProductData[
                                          'totalCancelledOrders'],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Total Sales',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  '\u20B1 ${currentProductData['totalSales'].toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w700,
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

                  // Sales Overview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sales Overview',
                        style: theme.textTheme.headlineMedium,
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSalesValue,
                          items: ['Daily', 'Weekly', 'Monthly', 'Annual']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSalesValue = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildChart(selectedSalesValue, currentProductData),
                ],
              ),
            ),
    );
  }
}

// Helper Method for Max Y-Value
double _getMaxY(Map<DateTime, double> dataMap) {
  return dataMap.values.isNotEmpty
      ? dataMap.values.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b)
      : 0.0;
}

// Helper Method for Chart
Widget _buildChart(String selectedValue, Map<String, dynamic> data) {
  switch (selectedValue) {
    case 'Daily':
      return Chart(
          dataMap: data['dailySalesMap'],
          maxXValue: 14,
          maxYValue: _getMaxY(data['dailySalesMap']));
    case 'Weekly':
      return Chart(
          dataMap: data['weeklySalesMap'],
          maxXValue: 4,
          maxYValue: _getMaxY(data['weeklySalesMap']));
    case 'Monthly':
      return Chart(
          dataMap: data['monthlySalesMap'],
          maxXValue: 6,
          maxYValue: _getMaxY(data['monthlySalesMap']));
    default:
      return Chart(
          dataMap: data['annualSalesMap'],
          maxXValue: 3,
          maxYValue: _getMaxY(data['annualSalesMap']));
  }
}

// Helper Method for Stats
Widget _buildStatColumn(BuildContext context, String title, int value) {
  final theme = Theme.of(context);
  return Column(
    children: [
      Text(title, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppTheme.spacing4),
      Text(
        '$value',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
