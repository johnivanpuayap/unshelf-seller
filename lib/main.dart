import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/core/interfaces/i_analytics_service.dart';
import 'package:unshelf_seller/core/interfaces/i_batch_service.dart';
import 'package:unshelf_seller/core/interfaces/i_bundle_service.dart';
import 'package:unshelf_seller/core/interfaces/i_notification_service.dart';
import 'package:unshelf_seller/core/interfaces/i_order_service.dart';
import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/analytics_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/batch_history_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/settings_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/user_profile_viewmodel.dart';
import 'package:unshelf_seller/views/home_view.dart';
import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/product_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/store_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/store_location_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/restock_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/listing_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/dashboard_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/product_summary_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/notification_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/batch_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/select_products_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/product_analytics_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/inventory_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );
  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(
          create: (_) => OrderViewModel(
            orderService: locator<IOrderService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productService: locator<IProductService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StoreViewModel(
            storeService: locator<IStoreService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StoreLocationViewModel(
            storeService: locator<IStoreService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RestockViewModel(
            productService: locator<IProductService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BundleViewModel(
            bundleService: locator<IBundleService>(),
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(
            create: (_) => UserProfileViewModel(userProfile: null)),
        ChangeNotifierProvider(
          create: (_) => ListingViewModel(
            productService: locator<IProductService>(),
            bundleService: locator<IBundleService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductSummaryViewModel(
            productService: locator<IProductService>(),
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(
            notificationService: locator<INotificationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BatchViewModel(
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SelectProductsViewModel(
            batchService: locator<IBatchService>(),
            productService: locator<IProductService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductAnalyticsViewModel(
            productService: locator<IProductService>(),
            analyticsService: locator<IAnalyticsService>(),
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryViewModel(
            productService: locator<IProductService>(),
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BatchHistoryViewModel(
            orderService: locator<IOrderService>(),
            batchService: locator<IBatchService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            notificationService: locator<INotificationService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unshelf',
      theme: AppTheme.lightTheme,
      home:
          FirebaseAuth.instance.currentUser != null ? const HomeView() : const LoginView(),
    );
  }
}
