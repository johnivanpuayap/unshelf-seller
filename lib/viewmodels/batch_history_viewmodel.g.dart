// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_history_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$batchHistoryViewModelHash() =>
    r'c0b9a3f189ebf6d6881e427664efee2f39ec7442';

/// Batch History ViewModel — fetches order history for a specific batch
/// and maintains a hard-coded demo [batchHistory] map alongside the live
/// orders list.
///
/// Preserves the original (pre-migration) behavior of computing
/// totalSaleSize / totalProductsSold inside [fetchBatchHistory] but never
/// surfacing them on state — they're written into [batchHistory] and the
/// view reads only the seeded map keys. The notifier keeps this mutable
/// map as a notifier-side field (it's not in state because it's
/// effectively static demo data plus per-fetch writes).
///
/// Copied from [BatchHistoryViewModel].
@ProviderFor(BatchHistoryViewModel)
final batchHistoryViewModelProvider = AutoDisposeNotifierProvider<
    BatchHistoryViewModel, BatchHistoryState>.internal(
  BatchHistoryViewModel.new,
  name: r'batchHistoryViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batchHistoryViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BatchHistoryViewModel = AutoDisposeNotifier<BatchHistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
