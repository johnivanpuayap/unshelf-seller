import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/viewmodels/store_profile_viewmodel.dart';

class EditStoreProfileView extends ConsumerStatefulWidget {
  final StoreModel storeDetails;

  const EditStoreProfileView({super.key, required this.storeDetails});

  @override
  ConsumerState<EditStoreProfileView> createState() =>
      _EditStoreProfileViewState();
}

class _EditStoreProfileViewState extends ConsumerState<EditStoreProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storeProfileViewModelProvider.notifier)
          .loadFromStore(widget.storeDetails);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProfileViewModelProvider);
    final notifier = ref.read(storeProfileViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Store Profile',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => notifier.pickImage(),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: state.profileImage != null
                            ? MemoryImage(state.profileImage!)
                            : widget.storeDetails.storeImageUrl != null
                                ? NetworkImage(
                                    widget.storeDetails.storeImageUrl!)
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
                    controller: notifier.nameController,
                    decoration:
                        const InputDecoration(labelText: 'Store Name'),
                  ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.center,
                    child: CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        await notifier.updateStoreProfile();
                        if (!context.mounted) return;
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
      ),
    );
  }
}
