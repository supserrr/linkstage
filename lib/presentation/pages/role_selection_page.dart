import 'package:flutter/material.dart';

import '../widgets/atoms/glass_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_borders.dart';
import '../bloc/role_selection/role_selection_cubit.dart';
import '../bloc/role_selection/role_selection_state.dart';
import '../../core/di/injection.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/router/app_router.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/user/upsert_user_usecase.dart';
import '../widgets/atoms/app_button.dart';

/// Role selection after registration (Event Planner vs Creative Professional).
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoleSelectionCubit(sl<UpsertUserUseCase>()),
      child: BlocConsumer<RoleSelectionCubit, RoleSelectionState>(
        listener: (context, state) {
          if (state.status == RoleSelectionStatus.success &&
              state.user != null) {
            context.go(AppRoutes.profileSetup, extra: state.user);
          }
          if (state.status == RoleSelectionStatus.error &&
              state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          return _RoleSelectionView(user: user);
        },
      ),
    );
  }
}

class _RoleSelectionView extends StatefulWidget {
  const _RoleSelectionView({required this.user});

  final UserEntity user;

  @override
  State<_RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<_RoleSelectionView> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoleSelectionCubit>().state;
    final user = widget.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/role_page_illustration_dark.svg'
        : 'assets/images/role_page_illustration_light.svg';

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: SvgPicture.asset(asset, fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Choose your role below',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _RoleCard(
                              title: 'Event Planner',
                              isSelected:
                                  _selectedRole == UserRole.eventPlanner,
                              onTap: () => setState(
                                () => _selectedRole = UserRole.eventPlanner,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'or',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _RoleCard(
                              title: 'Creative Professional',
                              isSelected:
                                  _selectedRole ==
                                  UserRole.creativeProfessional,
                              onTap: () => setState(
                                () => _selectedRole =
                                    UserRole.creativeProfessional,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                    labelLarge: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontSize: 16),
                  ),
                ),
                child: AppButton(
                  label: 'Get started',
                  onPressed:
                      _selectedRole == null ||
                          state.status == RoleSelectionStatus.loading
                      ? null
                      : () => context.read<RoleSelectionCubit>().selectRole(
                          user,
                          _selectedRole!,
                        ),
                  isLoading: state.status == RoleSelectionStatus.loading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  static const Color _selectedColor = Color(0xFFFF3131);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? _selectedColor
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isSelected ? Colors.white : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.borderRadius,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppBorders.borderRadius,
          ),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
