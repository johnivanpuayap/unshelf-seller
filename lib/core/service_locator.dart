import 'package:get_it/get_it.dart';

import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/interfaces/i_analytics_service.dart';
import 'package:unshelf_seller/core/interfaces/i_auth_service.dart';
import 'package:unshelf_seller/core/interfaces/i_batch_service.dart';
import 'package:unshelf_seller/core/interfaces/i_bundle_service.dart';
import 'package:unshelf_seller/core/interfaces/i_chat_service.dart';
import 'package:unshelf_seller/core/interfaces/i_notification_service.dart';
import 'package:unshelf_seller/core/interfaces/i_order_service.dart';
import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/interfaces/i_wallet_service.dart';
import 'package:unshelf_seller/data/repositories/auth_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_auth_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_orders_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_products_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_storage_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_stores_repository.dart';
import 'package:unshelf_seller/data/repositories/firebase/firebase_user_repository.dart';
import 'package:unshelf_seller/data/repositories/orders_repository.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/data/repositories/storage_repository.dart';
import 'package:unshelf_seller/data/repositories/stores_repository.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/services/analytics_service.dart';
import 'package:unshelf_seller/services/authentication_service.dart';
import 'package:unshelf_seller/services/batch_service.dart';
import 'package:unshelf_seller/services/bundle_service.dart';
import 'package:unshelf_seller/services/chat_service.dart';
import 'package:unshelf_seller/services/notification_service.dart';
import 'package:unshelf_seller/services/order_service.dart';
import 'package:unshelf_seller/services/product_service.dart';
import 'package:unshelf_seller/services/store_service.dart';
import 'package:unshelf_seller/services/user_profile_service.dart';
import 'package:unshelf_seller/services/wallet_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Core
  locator.registerLazySingleton<CurrentUserProvider>(
    () => CurrentUserProvider(),
  );

  // Services
  locator.registerLazySingleton<IAuthService>(
    () => AuthService(),
  );

  locator.registerLazySingleton<IProductService>(
    () => ProductService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IBundleService>(
    () => BundleService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IBatchService>(
    () => BatchService(
      currentUser: locator<CurrentUserProvider>(),
      productService: locator<IProductService>(),
    ),
  );

  locator.registerLazySingleton<IOrderService>(
    () => OrderService(
      currentUser: locator<CurrentUserProvider>(),
      batchService: locator<IBatchService>(),
      bundleService: locator<IBundleService>(),
    ),
  );

  locator.registerLazySingleton<IChatService>(
    () => ChatService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IStoreService>(
    () => StoreService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<INotificationService>(
    () => NotificationService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IAnalyticsService>(
    () => AnalyticsService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IWalletService>(
    () => WalletService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  locator.registerLazySingleton<IUserProfileService>(
    () => UserProfileService(
      currentUser: locator<CurrentUserProvider>(),
    ),
  );

  // Repositories (data layer)
  locator.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  locator.registerLazySingleton<StoresRepository>(() => FirebaseStoresRepository());
  locator.registerLazySingleton<OrdersRepository>(() => FirebaseOrdersRepository());
  locator.registerLazySingleton<ProductsRepository>(() => FirebaseProductsRepository());
  locator.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
  locator.registerLazySingleton<StorageRepository>(() => FirebaseStorageRepository());
}
