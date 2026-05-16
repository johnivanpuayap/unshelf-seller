import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/models/transaction_model.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';
import 'package:unshelf_seller/views/withdraw_request_view.dart';

/// Wallet balance overview.
///
/// Layout (per Group F design intent, plan line 1457):
/// hero balance card → KPI row → recent transactions list.
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

  Future<void> _refresh() async {
    await ref.read(walletViewModelProvider.notifier).updateTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final walletState = ref.watch(walletViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Wallet',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _refresh,
        child: _Body(state: walletState),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Body — switches between loading / error / content
// ────────────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.transactions.isEmpty && state.balance == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          _InlineError(
            message: state.errorMessage!,
            onRetry: () => ref
                .read(walletViewModelProvider.notifier)
                .updateTransactions(),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        _HeroBalance(balance: state.balance),
        const SizedBox(height: 24),
        _LifetimeKpiRow(transactions: state.transactions),
        const SizedBox(height: 32),
        _TransactionsSection(state: state),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero balance card — large balance + Withdraw CTA
// ────────────────────────────────────────────────────────────────────────────

class _HeroBalance extends StatelessWidget {
  const _HeroBalance({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Available balance',
                style: tt.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money.format(balance),
              style: tt.displaySmall?.copyWith(color: cs.onSurface),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: balance <= 0
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WithdrawRequestView(),
                        ),
                      ),
              icon: const Icon(Icons.arrow_outward_rounded, size: 20),
              label: Text(
                'Withdraw',
                style: tt.labelLarge?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Lifetime KPI row — earnings / withdrawals derived from transactions
// ────────────────────────────────────────────────────────────────────────────

class _LifetimeKpiRow extends StatelessWidget {
  const _LifetimeKpiRow({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    double lifetimeEarnings = 0;
    double lifetimeWithdrawals = 0;
    for (final t in transactions) {
      if (t.type == StatusConstants.withdraw) {
        lifetimeWithdrawals += t.amount;
      } else if (t.type == StatusConstants.sale) {
        lifetimeEarnings += t.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Lifetime earnings',
            value: money.format(lifetimeEarnings),
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'Withdrawn',
            value: money.format(lifetimeWithdrawals),
            icon: Icons.arrow_outward_rounded,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Transactions section — themed list, signed amounts, no dividers
// ────────────────────────────────────────────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    final transactions = [...state.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent transactions'),
        if (transactions.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle:
                'Sales and withdrawals will appear here as they happen.',
          )
        else
          Column(
            children: [
              for (final t in transactions) ...[
                _TransactionRow(transaction: t),
                if (t != transactions.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    final isOutflow = transaction.type == StatusConstants.withdraw ||
        transaction.type == 'Commission Fee';
    final amountColor = isOutflow ? cs.error : cs.primary;
    final sign = isOutflow ? '-' : '+';
    final icon = isOutflow
        ? Icons.arrow_outward_rounded
        : Icons.arrow_downward_rounded;

    final label = switch (transaction.type) {
      StatusConstants.withdraw => 'Withdrawal',
      StatusConstants.sale => 'Sale',
      'Commission Fee' => 'Commission fee',
      _ => transaction.type,
    };

    final dateLabel = DateFormat('MMM d, yyyy').format(transaction.date);

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 20, color: amountColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign${money.format(transaction.amount)}',
            style: tt.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Inline error widget — mirrors Group A dashboard
// ────────────────────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: cs.error),
          const SizedBox(height: 8),
          Text(
            "Couldn't load your wallet",
            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
