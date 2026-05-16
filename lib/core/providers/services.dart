/// Riverpod bridge providers for `get_it`-registered service interfaces.
///
/// These thin providers expose each `IFooService` (registered in
/// [setupLocator]) to Riverpod-powered ViewModels and screens. Each
/// ViewModel migration adds the service(s) it needs here, so that the
/// `get_it` → Riverpod transition is one-directional and gradual.
///
/// When the repository layer lands (Phase 3 of the seller rebrand), these
/// bridges may be replaced by direct Riverpod providers backed by
/// `Repository` classes — but for the duration of Phase 2, the bridge
/// keeps service registration in `setupLocator` and avoids rewriting
/// every consumer in one go.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/interfaces/i_analytics_service.dart';
import 'package:unshelf_seller/core/interfaces/i_batch_service.dart';
import 'package:unshelf_seller/core/interfaces/i_notification_service.dart';
import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
IAnalyticsService analyticsService(AnalyticsServiceRef ref) =>
    locator<IAnalyticsService>();

@Riverpod(keepAlive: true)
INotificationService notificationService(NotificationServiceRef ref) =>
    locator<INotificationService>();

@Riverpod(keepAlive: true)
IProductService productService(ProductServiceRef ref) =>
    locator<IProductService>();

@Riverpod(keepAlive: true)
IBatchService batchService(BatchServiceRef ref) => locator<IBatchService>();
