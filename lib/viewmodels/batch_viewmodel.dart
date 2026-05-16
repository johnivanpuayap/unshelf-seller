import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';

part 'batch_viewmodel.g.dart';

/// Immutable state for the batch add/edit screens.
///
/// `TextEditingController`s remain owned by the notifier (they're imperative
/// widget glue rather than state); see [BatchViewModel].
class BatchState {
  final bool isLoading;
  final String? errorMessage;
  final String? batchNumber;
  final DateTime? expiryDate;
  final double? price;
  final int? stock;
  final String? quantifier;
  final int? discount;

  const BatchState({
    required this.isLoading,
    required this.errorMessage,
    required this.batchNumber,
    required this.expiryDate,
    required this.price,
    required this.stock,
    required this.quantifier,
    required this.discount,
  });

  factory BatchState.initial() => const BatchState(
        isLoading: false,
        errorMessage: null,
        batchNumber: null,
        expiryDate: null,
        price: null,
        stock: null,
        quantifier: null,
        discount: null,
      );

  BatchState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? batchNumber = _sentinel,
    Object? expiryDate = _sentinel,
    Object? price = _sentinel,
    Object? stock = _sentinel,
    Object? quantifier = _sentinel,
    Object? discount = _sentinel,
  }) {
    return BatchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      batchNumber: identical(batchNumber, _sentinel)
          ? this.batchNumber
          : batchNumber as String?,
      expiryDate: identical(expiryDate, _sentinel)
          ? this.expiryDate
          : expiryDate as DateTime?,
      price: identical(price, _sentinel) ? this.price : price as double?,
      stock: identical(stock, _sentinel) ? this.stock : stock as int?,
      quantifier: identical(quantifier, _sentinel)
          ? this.quantifier
          : quantifier as String?,
      discount:
          identical(discount, _sentinel) ? this.discount : discount as int?,
    );
  }

  static const _sentinel = Object();
}

/// Batch ViewModel — backs the add/edit batch screens. Owns a small set
/// of `TextEditingController`s (kept on the notifier instance rather than
/// in [BatchState], since they're imperative widget glue, not "state").
@riverpod
class BatchViewModel extends _$BatchViewModel {
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController quantifierController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  @override
  BatchState build() {
    ref.onDispose(() {
      batchNumberController.dispose();
      expiryDateController.dispose();
      priceController.dispose();
      stockController.dispose();
      quantifierController.dispose();
      discountController.dispose();
    });
    return BatchState.initial();
  }

  set expiryDate(DateTime? date) {
    state = state.copyWith(expiryDate: date);
  }

  set price(double? value) {
    state = state.copyWith(price: value);
  }

  set stock(int? value) {
    state = state.copyWith(stock: value);
  }

  set quantifier(String? value) {
    state = state.copyWith(quantifier: value);
  }

  set discount(int? value) {
    state = state.copyWith(discount: value);
  }

  /// Adds a new batch via the batch service. Returns `true` on success.
  Future<bool> addBatch(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(batchServiceProvider).addBatch(
            productId: productId,
            batchNumber: batchNumberController.text,
            price: double.tryParse(priceController.text) ?? 0.0,
            stock: int.tryParse(stockController.text) ?? 0,
            quantifier: quantifierController.text,
            expiryDate: state.expiryDate!,
            discount: discountController.text.isNotEmpty
                ? int.tryParse(discountController.text) ?? 0
                : 0,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error in BatchViewModel.addBatch: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> fetchBatch(String batchNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final batch = await ref.read(batchServiceProvider).getBatchById(batchNumber);
      if (batch != null) {
        batchNumberController.text = batchNumber;
        expiryDateController.text =
            DateFormat('MM-dd-yyyy').format(batch.expiryDate);
        priceController.text = batch.price.toString();
        stockController.text = batch.stock.toString();
        quantifierController.text = batch.quantifier;
        discountController.text = batch.discount.toString();
        state = state.copyWith(
          isLoading: false,
          batchNumber: batchNumber,
          expiryDate: batch.expiryDate,
        );
      } else {
        state = state.copyWith(isLoading: false, batchNumber: batchNumber);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in BatchViewModel.fetchBatch: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateBatch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      AppLogger.debug('Updating batch');
      await ref.read(batchServiceProvider).updateBatch(
            batchNumberController.text,
            priceController.text.isNotEmpty
                ? double.tryParse(priceController.text) ?? 0.0
                : 0.0,
            stockController.text.isNotEmpty
                ? int.tryParse(stockController.text) ?? 0
                : 0,
            quantifierController.text.isNotEmpty
                ? quantifierController.text
                : '',
            state.expiryDate!,
            discountController.text.isNotEmpty
                ? int.tryParse(discountController.text) ?? 0
                : 0,
          );
      AppLogger.debug('Batch updated');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchViewModel.updateBatch: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearData() {
    batchNumberController.clear();
    expiryDateController.clear();
    priceController.clear();
    stockController.clear();
    quantifierController.clear();
    discountController.clear();
    state = BatchState.initial();
  }
}
