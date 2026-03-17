import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../atoms/glass_card.dart';
import '../../../core/constants/app_borders.dart';
import '../../../core/utils/image_url_utils.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../domain/entities/profile_entity.dart';

/// Card displaying a creative professional (vendor) for discovery list.
class VendorCard extends StatelessWidget {
  const VendorCard({
    super.key,
    required this.profile,
    this.onTap,
    this.isSaved = false,
    this.onSaveTap,
  });

  final ProfileEntity profile;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSaveTap;

  static const double _imageSize = 96;
  static const double _imageRadius = AppBorders.radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = profile.displayName ?? 'Creative Professional';
    final role = _roleLabel(profile);
    final location =
        profile.location.isNotEmpty ? profile.location : '—';

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_imageRadius),
                child: SizedBox(
                  width: _imageSize,
                  height: _imageSize,
                  child: _hasProfileImage(profile)
                      ? CachedNetworkImage(
                          imageUrl: ImageUrlUtils.thumbnailUrl(
                            _profileImageUrl(profile),
                            width: _imageSize.round(),
                            height: _imageSize.round(),
                          ),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              AppIcons.person,
                              size: 44,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              AppIcons.person,
                              size: 44,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            AppIcons.person,
                            size: 44,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.rating > 0 || profile.reviewCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            AppIcons.rating,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.rating.toStringAsFixed(1),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.reviewCount == 1
                                ? '1 review'
                                : '${NumberFormatter.formatInteger(profile.reviewCount)} reviews',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          AppIcons.location,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (profile.priceRange.isNotEmpty)
                      Text(
                        _formatRate(profile.priceRange),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (onSaveTap != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: onSaveTap,
                          icon: Icon(
                            isSaved ? AppIcons.savedFilled : AppIcons.savedOutline,
                            size: 22,
                            color: isSaved
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(36, 36),
                          ),
                          tooltip: isSaved ? 'Remove from saved' : 'Save creative',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasProfileImage(ProfileEntity p) {
    return p.photoUrl != null && p.photoUrl!.isNotEmpty;
  }

  String _profileImageUrl(ProfileEntity p) {
    return p.photoUrl!;
  }

  String _formatRate(String priceRange) {
    final formatted = NumberFormatter.formatNumbersInString(priceRange);
    final withRwf = formatted.trimLeft().toUpperCase().startsWith('RWF')
        ? formatted
        : 'RWF $formatted';
    return withRwf.contains('/') ? withRwf : '$withRwf / hr';
  }

  /// Prefer profession (e.g. "Jazz Vocalist") when set; otherwise category (e.g. "Photographer").
  String _roleLabel(ProfileEntity p) {
    if (p.professions.isNotEmpty) return p.professions.first;
    if (p.category != null) return _categoryLabel(p.category!);
    return 'Creative';
  }

  String _categoryLabel(ProfileCategory cat) {
    switch (cat) {
      case ProfileCategory.dj:
        return 'DJ';
      case ProfileCategory.photographer:
        return 'Photographer';
      case ProfileCategory.decorator:
        return 'Decorator';
      case ProfileCategory.contentCreator:
        return 'Content Creator';
    }
  }
}
