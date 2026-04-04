import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/repositories/profile_repository.dart';

/// Full-screen portfolio view showing all uploaded photos and videos for a creative.
class ProfilePortfolioPage extends StatelessWidget {
  const ProfilePortfolioPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: FutureBuilder<ProfileEntity?>(
        future: sl<ProfileRepository>().getProfileByUserId(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Text(
                'Profile not found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          final imageUrls = profile.portfolioUrls;
          final videoUrls = profile.portfolioVideoUrls;
          final total = imageUrls.length + videoUrls.length;
          if (total == 0) {
            return Center(
              child: Text(
                'No portfolio media yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: total,
            itemBuilder: (context, index) {
              if (index < imageUrls.length) {
                return ClipRRect(
                  borderRadius: AppBorders.borderRadius,
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  borderRadius: AppBorders.borderRadius,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
