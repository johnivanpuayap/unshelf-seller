// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$batchViewModelHash() => r'93e5a8df6b2c170bf5aa43d7d0389cf72a1d8ce4';

/// Batch ViewModel — backs the add/edit batch screens. Owns a small set
/// of `TextEditingController`s (kept on the notifier instance rather than
/// in [BatchState], since they're imperative widget glue, not "state").
///
/// Copied from [BatchViewModel].
@ProviderFor(BatchViewModel)
final batchViewModelProvider =
    AutoDisposeNotifierProvider<BatchViewModel, BatchState>.internal(
  BatchViewModel.new,
  name: r'batchViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batchViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BatchViewModel = AutoDisposeNotifier<BatchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
