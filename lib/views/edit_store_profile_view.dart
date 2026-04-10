import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/viewmodels/store_profile_viewmodel.dart';

class EditStoreProfileView extends StatelessWidget {
  final StoreModel storeDetails;

  const EditStoreProfileView({super.key, required this.storeDetails});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StoreProfileViewModel>(
      create: (_) => StoreProfileViewModel(storeDetails,
        storeService: locator<IStoreService>()),
      child: Scaffold(
        appBar: CustomAppBar(
            title: 'Edit Store Profile',
            onBackPressed: () {
              Navigator.pop(context);
            }),
        body: Consumer<StoreProfileViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: ListView(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () => viewModel.pickImage(),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              backgroundImage: viewModel.profileImage != null
                                  ? MemoryImage(viewModel.profileImage!)
                                  : storeDetails.storeImageUrl != null
                                      ? NetworkImage(
                                          storeDetails.storeImageUrl!)
                                      : null,
                              child: const Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(Icons.camera_alt,
                                    color: AppColors.primaryColor, size: 30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: viewModel.nameController,
                          decoration:
                              const InputDecoration(labelText: 'Store Name'),
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.center,
                          child: CustomButton(
                            text: 'Save Changes',
                            onPressed: () async {
                              await viewModel.updateStoreProfile();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Store Profile updated successfully!')),
                              );
                              Navigator.pop(context, true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
