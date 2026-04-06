import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../data/datasources/portfolio_storage_datasource.dart';
import '../../bloc/onboarding/onboarding_cubit.dart';
import '../../bloc/onboarding/profile_setup_cubit.dart';
import '../../bloc/onboarding/profile_setup_draft_storage.dart';
import '../../bloc/onboarding/profile_setup_flow_cubit.dart';
import '../../bloc/onboarding/profile_setup_state.dart';
import '../../bloc/onboarding/username_step_cubit.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/user/upsert_user_usecase.dart';
import '../onboarding/widgets/display_name_step.dart';
import '../onboarding/widgets/profile_photo_step.dart';
import '../onboarding/widgets/username_step.dart';

/// Post-auth profile setup flow (step-by-step).
class ProfileSetupFlowPage extends StatefulWidget {
  const ProfileSetupFlowPage({super.key, required this.user});

  final UserEntity user;

  @override
  State<ProfileSetupFlowPage> createState() => _ProfileSetupFlowPageState();
}

class _ProfileSetupFlowPageState extends State<ProfileSetupFlowPage> {
  late final PageController _pageController;
  late final List<_StepConfig> _steps;
  late final int _initialStep;
  ProfileSetupState? _initialDraft;

  @override
  void initState() {
    super.initState();
    _steps = [
      _StepConfig(title: 'Username', isCreative: false),
      _StepConfig(title: 'Photo', isCreative: false),
      _StepConfig(title: 'Name', isCreative: false),
    ];
    final draft = sl<ProfileSetupDraftStorage>().loadDraft(widget.user.id);
    if (draft != null) {
      _initialStep = draft.step.clamp(0, _steps.length - 1);
      _initialDraft = draft.state;
    } else {
      _initialStep = 0;
    }
    _pageController = PageController(initialPage: _initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(BuildContext blocContext) {
    final flow = blocContext.read<ProfileSetupFlowCubit>();
    final step = flow.state;
    if (step < _steps.length - 1) {
      final newStep = step + 1;
      final cubitState = blocContext.read<ProfileSetupCubit>().state;
      sl<ProfileSetupDraftStorage>().saveDraft(
        widget.user.id,
        newStep,
        cubitState,
      );
      flow.setStep(newStep);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit(blocContext);
    }
  }

  Future<void> _submit(BuildContext blocContext) async {
    await blocContext.read<ProfileSetupCubit>().submit();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProfileSetupFlowCubit(_initialStep)),
        BlocProvider(
          create: (_) => ProfileSetupCubit(
            widget.user,
            sl<UpsertUserUseCase>(),
            sl<ProfileRepository>(),
            sl<UserRepository>(),
            sl<PortfolioStorageDataSource>(),
            sl<AuthRepository>(),
            initialDraft: _initialDraft,
          ),
        ),
      ],
      child: BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
        listenWhen: (a, b) => b.success || b.error != null,
        listener: (context, state) async {
          if (state.success) {
            sl<ProfileSetupDraftStorage>().clearDraft(widget.user.id);
            await sl<OnboardingCubit>().setProfileComplete();
            await sl<AuthRedirectNotifier>().refresh();
            if (!context.mounted) return;
            context.go(AppRoutes.home);
          }
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          final colorScheme = Theme.of(context).colorScheme;
          final currentStep = context.watch<ProfileSetupFlowCubit>().state;
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (currentStep > 0) {
                    final newStep = currentStep - 1;
                    final profileCubit = context.read<ProfileSetupCubit>();
                    final flowCubit = context.read<ProfileSetupFlowCubit>();
                    final cubitState = profileCubit.state;
                    await sl<ProfileSetupDraftStorage>().saveDraft(
                      widget.user.id,
                      newStep,
                      cubitState,
                    );
                    if (!context.mounted) return;
                    flowCubit.setStep(newStep);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    final router = GoRouter.of(context);
                    final user = widget.user;
                    await sl<ProfileSetupDraftStorage>().clearDraft(user.id);
                    if (context.mounted) {
                      router.go(AppRoutes.roleSelection, extra: user);
                    }
                  }
                },
              ),
              title: Text(
                '${currentStep + 1} of ${_steps.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _buildStepWidgets(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStepWidgets(BuildContext blocContext) {
    final cubit = blocContext.read<ProfileSetupCubit>();
    void onNext() => _next(blocContext);

    return [
      BlocProvider(
        create: (c) => UsernameStepCubit(c.read<ProfileSetupCubit>()),
        child: UsernameStep(onNext: onNext),
      ),
      ProfilePhotoStep(onNext: onNext),
      DisplayNameStep(initialValue: cubit.state.displayName, onNext: onNext),
    ];
  }
}

class _StepConfig {
  _StepConfig({required this.title, required this.isCreative});

  final String title;
  final bool isCreative;
}
