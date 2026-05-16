import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/field_label.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';

/// Withdraw request form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// `FieldLabel` pattern, mirroring the auth screens.
class WithdrawRequestView extends ConsumerStatefulWidget {
  const WithdrawRequestView({super.key});

  @override
  ConsumerState<WithdrawRequestView> createState() =>
      _WithdrawRequestViewState();
}

enum _PayoutMethod { bank, gcash }

class _WithdrawRequestViewState extends ConsumerState<WithdrawRequestView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _gcashNumberController = TextEditingController();

  _PayoutMethod _method = _PayoutMethod.bank;
  String? _selectedBank;
  bool _submitting = false;

  static const _minWithdrawal = 1000.0;

  final List<String> _phBanks = const [
    'BDO',
    'BPI',
    'Metrobank',
    'LandBank',
    'Security Bank',
    'UnionBank',
    'PNB',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _bankAccountController.dispose();
    _gcashNumberController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit(double availableBalance) async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final accountName = _accountNameController.text.trim();
    final String channelName;
    final String channelAccount;
    if (_method == _PayoutMethod.bank) {
      channelName = _selectedBank!;
      channelAccount = _bankAccountController.text.trim();
    } else {
      channelName = 'GCash';
      channelAccount = _gcashNumberController.text.trim();
    }

    setState(() => _submitting = true);
    try {
      await ref.read(walletViewModelProvider.notifier).withdrawRequest(
            amount,
            accountName,
            channelName,
            channelAccount,
          );

      final error = ref.read(walletViewModelProvider).errorMessage;
      if (error != null) {
        _snack("Couldn't submit withdrawal. Please try again.");
        return;
      }

      _snack('Withdrawal requested');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      _snack("Couldn't submit withdrawal. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final walletState = ref.watch(walletViewModelProvider);
    final balance = walletState.balance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request withdrawal',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Withdraw funds',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send earnings to your bank or GCash account. Minimum withdrawal is ₱${_minWithdrawal.toStringAsFixed(0)}.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available balance display card
                    _BalanceDisplay(balance: balance),
                    const SizedBox(height: 32),

                    // Amount
                    FieldLabel('Amount', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        prefixText: '₱ ',
                        hintText: '0.00',
                      ),
                      validator: (v) {
                        final raw = v?.trim() ?? '';
                        if (raw.isEmpty) return 'Amount is required';
                        final parsed = double.tryParse(raw);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (parsed < _minWithdrawal) {
                          return 'Minimum withdrawal is ₱${_minWithdrawal.toStringAsFixed(0)}';
                        }
                        if (parsed > balance) {
                          return 'Amount exceeds available balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Payment method
                    FieldLabel('Payment method', color: cs.onSurface),
                    const SizedBox(height: 8),
                    _MethodToggle(
                      value: _method,
                      onChanged: (m) => setState(() {
                        _method = m;
                        // Reset bank-specific selection when switching away.
                        if (m == _PayoutMethod.gcash) _selectedBank = null;
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Account name
                    FieldLabel('Account name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Full name on the account',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Account name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_method == _PayoutMethod.bank) ...[
                      // Bank
                      FieldLabel('Bank', color: cs.onSurface),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBank,
                        items: _phBanks
                            .map(
                              (b) => DropdownMenuItem<String>(
                                value: b,
                                child: Text(b),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          hintText: 'Select a bank',
                        ),
                        onChanged: (v) => setState(() => _selectedBank = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Bank is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Account number
                      FieldLabel('Account number', color: cs.onSurface),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bankAccountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1234567890',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Account number is required';
                          }
                          if (v.trim().length < 6) {
                            return 'Enter a valid account number';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // GCash number
                      FieldLabel('GCash number', color: cs.onSurface),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _gcashNumberController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          hintText: '09XXXXXXXXX',
                        ),
                        validator: (v) {
                          final raw = v?.trim() ?? '';
                          if (raw.isEmpty) return 'GCash number is required';
                          if (raw.length != 11 || !raw.startsWith('09')) {
                            return 'Enter a valid 11-digit number starting with 09';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _submitting ? null : () => _submit(balance),
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Request withdrawal',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Available balance — read-only card at the top of the form
// ────────────────────────────────────────────────────────────────────────────

class _BalanceDisplay extends StatelessWidget {
  const _BalanceDisplay({required this.balance});

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available balance',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  money.format(balance),
                  style: tt.titleLarge?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Payment method toggle — two-segment pill
// ────────────────────────────────────────────────────────────────────────────

class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.value, required this.onChanged});

  final _PayoutMethod value;
  final ValueChanged<_PayoutMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodSegment(
              label: 'Bank',
              icon: Icons.account_balance_outlined,
              selected: value == _PayoutMethod.bank,
              onTap: () => onChanged(_PayoutMethod.bank),
            ),
          ),
          Expanded(
            child: _MethodSegment(
              label: 'GCash',
              icon: Icons.smartphone_outlined,
              selected: value == _PayoutMethod.gcash,
              onTap: () => onChanged(_PayoutMethod.gcash),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodSegment extends StatelessWidget {
  const _MethodSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? cs.onPrimary : cs.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  color: selected ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Field label (copied verbatim from auth screens)
// ────────────────────────────────────────────────────────────────────────────

