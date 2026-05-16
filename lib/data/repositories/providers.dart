/// Riverpod bridge providers for the data-layer repositories.
///
/// Each provider exposes a repository interface registered in [setupLocator]
/// (see `lib/core/service_locator.dart`) so that Riverpod-aware consumers can
/// `ref.read(authRepositoryProvider)` instead of reaching into `get_it`
/// directly. Keeps the `get_it` registration as the single composition root
/// while letting ViewModels stay framework-pure.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/data/repositories/auth_repository.dart';
import 'package:unshelf_seller/data/repositories/orders_repository.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/data/repositories/storage_repository.dart';
import 'package:unshelf_seller/data/repositories/stores_repository.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    locator<AuthRepository>();

@Riverpod(keepAlive: true)
StoresRepository storesRepository(StoresRepositoryRef ref) =>
    locator<StoresRepository>();

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(OrdersRepositoryRef ref) =>
    locator<OrdersRepository>();

@Riverpod(keepAlive: true)
ProductsRepository productsRepository(ProductsRepositoryRef ref) =>
    locator<ProductsRepository>();

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) =>
    locator<UserRepository>();

@Riverpod(keepAlive: true)
StorageRepository storageRepository(StorageRepositoryRef ref) =>
    locator<StorageRepository>();
