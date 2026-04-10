import 'package:flutter/material.dart';

import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

/// A card representing a product or bundle listing.
/// Used in the listings view.
class ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? category;
  final int? batchCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.category,
    this.batchCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: _ProductImage(imageUrl: imageUrl),
              ),

              const SizedBox(width: AppTheme.spacing12),

              // Name, category chip, batch count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category != null) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      _CategoryChip(label: category!),
                    ],
                    if (batchCount != null) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        '$batchCount ${batchCount == 1 ? 'batch' : 'batches'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // More options menu
              if (onEdit != null || onDelete != null)
                _OptionsMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private sub-widgets ─────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const size = 80.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _Placeholder(size: size),
      );
    }

    return const _Placeholder(size: size);
  }
}

class _Placeholder extends StatelessWidget {
  final double size;

  const _Placeholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
        size: 32,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OptionsMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      onSelected: (action) {
        if (action == _MenuAction.edit) onEdit?.call();
        if (action == _MenuAction.delete) onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: _MenuAction.edit,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: AppTheme.spacing8),
                Text('Edit'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: _MenuAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                SizedBox(width: AppTheme.spacing8),
                Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _MenuAction { edit, delete }
