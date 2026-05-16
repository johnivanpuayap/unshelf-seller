// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletViewModelHash() => r'9228acfba930d7b41958b9df61a20a42f312b224';

/// Wallet ViewModel — exposes the seller's running balance and transaction
/// history, derived from the wallet service's raw transaction docs.
///
/// Copied from [WalletViewModel].
@ProviderFor(WalletViewModel)
final walletViewModelProvider =
    AutoDisposeNotifierProvider<WalletViewModel, WalletState>.internal(
  WalletViewModel.new,
  name: r'walletViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WalletViewModel = AutoDisposeNotifier<WalletState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
