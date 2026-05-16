import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/viewmodels/store_profile_viewmodel.dart';

/// Edit Store Profile screen.
///
/// Quality-Bar form shell (maxWidth 420). Tap the avatar to pick a new image;
/// the bottom 52px pill commits via the viewmodel and pops with `true`.
class EditStoreProfileView extends ConsumerStatefulWidget {
  final StoreModel storeDetails;

  const EditStoreProfileView({super.key, required this.storeDetails});

  @override
  ConsumerState<EditStoreProfileView> createState() =>
      _EditStoreProfileViewState();
}

class _EditStoreProfileViewState extends ConsumerState<EditStoreProfileView> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(storeProfileViewModelProvider.notifier)
          .loadFromStore(widget.storeDetails);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(storeProfileViewModelProvider.notifier);
    await notifier.updateStoreProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store profile updated.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProfileViewModelProvider);
    final notifier = ref.read(storeProfileViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final saving = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit store profile',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarPicker(
                      currentUrl: widget.storeDetails.storeImageUrl,
                      onTap: saving ? () {} : notifier.pickImage,
                    ),
                    const SizedBox(height: 32),
                    _FieldLabel('Store name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lola Nena bakery',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Store name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Phone number', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '+63 9XX XXX XXXX',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Address', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.addressController,
                      textInputAction: TextInputAction.done,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Street, barangay, city',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: saving ? null : _save,
                        child: saving
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Avatar picker — tappable circle with a small camera badge overlay
// ────────────────────────────────────────────────────────────────────────────

class _AvatarPicker extends ConsumerWidget {
  const _AvatarPicker({required this.currentUrl, required this.onTap});

  final String? currentUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final picked = ref.watch(storeProfileViewModelProvider).profileImage;

    ImageProvider? imageProvider;
    if (picked != null) {
      imageProvider = MemoryImage(picked);
    } else if (currentUrl != null && currentUrl!.isNotEmpty) {
      imageProvider = NetworkImage(currentUrl!);
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2A20).withValues(alpha: .10),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: cs.surfaceContainerHighest,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Icon(
                            Icons.storefront_outlined,
                            size: 40,
                            color: cs.primary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      border: Border.all(color: cs.surface, width: 3),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: cs.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change photo',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Field label — Phase 1 Quality Bar form pattern
// ────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      );
}
