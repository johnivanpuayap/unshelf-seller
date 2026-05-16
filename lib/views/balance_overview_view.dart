import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';
import 'package:unshelf_seller/views/withdraw_request_view.dart';
import 'package:intl/intl.dart';

class BalanceOverviewView extends ConsumerStatefulWidget {
  const BalanceOverviewView({super.key});

  @override
  ConsumerState<BalanceOverviewView> createState() =>
      _BalanceOverviewViewState();
}

class _BalanceOverviewViewState extends ConsumerState<BalanceOverviewView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletViewModelProvider.notifier).updateTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletViewModelProvider);

    return Scaffold(
        appBar: CustomAppBar(
            title: 'Balance Overview',
            onBackPressed: () {
              Navigator.pop(context);
            }),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                child: Text(
                  'Current Balance',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Center(
                child: Text(
                  '₱ ${walletState.balance.toStringAsFixed(2)}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                child: Text(
                  'Transaction History',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: walletState.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = walletState.transactions[index];
                    bool isWithdrawal = (transaction.type == 'Withdraw' ||
                        transaction.type == 'Commission Fee');
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing8),
                      child: ListTile(
                        leading: Icon(
                          isWithdrawal
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isWithdrawal
                              ? AppColors.error
                              : AppColors.primaryColor,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transaction.type,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isWithdrawal
                                    ? AppColors.error
                                    : AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              '₱ ${transaction.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: isWithdrawal
                                    ? AppColors.error
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          DateFormat('MM-dd-yyyy')
                              .format(transaction.date.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                        tileColor: isWithdrawal
                            ? AppColors.statusCancelled
                            : AppColors.statusCompleted,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WithdrawRequestView(),
              ),
            );
          },
          child: Image.asset(
            'assets/icons/withdraw.png',
            width: 24,
            height: 24,
          ),
        ));
  }
}
