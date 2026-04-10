import 'package:flutter/material.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/components/custom_button.dart';

class WithdrawRequestView extends StatefulWidget {
  final WalletViewModel walletViewModel;

  const WithdrawRequestView({super.key, required this.walletViewModel});

  @override
  State<WithdrawRequestView> createState() => _WithdrawRequestViewState();
}

class _WithdrawRequestViewState extends State<WithdrawRequestView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  String _errorMessage = '';
  String? _selectedBank;

  final List<String> _phBanks = [
    'BDO',
    'BPI',
    'Metrobank',
    'LandBank',
    'Security Bank',
    'UnionBank',
    'PNB',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Withdraw Request',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance: \u20B1 ${widget.walletViewModel.balance.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Full Name Input Field
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  errorText:
                      _errorMessage.isNotEmpty && _errorMessage.contains('name')
                          ? _errorMessage
                          : null,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Bank Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                ),
                initialValue: _selectedBank,
                items: _phBanks
                    .map((bank) => DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Bank Account Number Input Field
              TextField(
                controller: _bankAccountController,
                decoration: InputDecoration(
                  labelText: 'Bank Account Number',
                  errorText: _errorMessage.isNotEmpty &&
                          _errorMessage.contains('account')
                      ? _errorMessage
                      : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Withdrawal Amount Input Field
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Withdrawal Amount',
                  errorText: _errorMessage.isNotEmpty &&
                          _errorMessage.contains('amount')
                      ? _errorMessage
                      : null,
                ),
                keyboardType: TextInputType.number,
              ),
              if (_errorMessage.isNotEmpty &&
                  !_errorMessage.contains('name') &&
                  !_errorMessage.contains('account') &&
                  !_errorMessage.contains('amount')) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  _errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
              // Submit Button
              CustomButton(
                onPressed: () {
                  final double? amount =
                      double.tryParse(_amountController.text);
                  final String fullName = _fullNameController.text.trim();
                  final String bankAccount = _bankAccountController.text.trim();

                  setState(() {
                    // Validate all fields
                    if (fullName.isEmpty) {
                      _errorMessage = 'Please enter your full name.';
                    } else if (_selectedBank == null) {
                      _errorMessage = 'Please select a bank.';
                    } else if (bankAccount.isEmpty) {
                      _errorMessage = 'Please enter your bank account number.';
                    } else if (amount == null || amount <= 0) {
                      _errorMessage = 'Please enter a valid amount.';
                    } else if (amount < 1000) {
                      _errorMessage = 'The minimum withdrawal amount is 1000.';
                    } else if (widget.walletViewModel.balance < amount) {
                      _errorMessage =
                          'Insufficient balance for this withdrawal.';
                    } else {
                      // Reset error message
                      _errorMessage = '';

                      // Call the withdraw request
                      widget.walletViewModel.withdrawRequest(
                          amount, fullName, _selectedBank!, bankAccount);
                      Navigator.pop(context);
                    }
                  });
                },
                text: 'Submit Request',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
