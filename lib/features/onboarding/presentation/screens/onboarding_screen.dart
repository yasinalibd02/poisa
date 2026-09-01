import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/kori_logo.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/language_choice_card.dart';
import '../widgets/onboarding_slide.dart';

/// Three value slides followed by the language step. Finishing sets
/// `onboarding_done`, which the router's guard watches.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _pageCount = 4;
  int get _languagePage => _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: AppSizes.normal,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final bool onLanguageStep = _page == _languagePage;

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedOpacity(
                  duration: AppSizes.fast,
                  opacity: onLanguageStep ? 0 : 1,
                  child: TextButton(
                    onPressed: onLanguageStep
                        ? null
                        : () => _goTo(_languagePage),
                    child: Text(context.l10n.actionSkip),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (int page) => setState(() => _page = page),
                  children: <Widget>[
                    OnboardingSlide(
                      icon: Icons.savings_rounded,
                      title: context.l10n.onboard1Title,
                      body: context.l10n.onboard1Body,
                    ),
                    OnboardingSlide(
                      icon: Icons.track_changes_rounded,
                      title: context.l10n.onboard2Title,
                      body: context.l10n.onboard2Body,
                    ),
                    OnboardingSlide(
                      icon: Icons.insights_rounded,
                      title: context.l10n.onboard3Title,
                      body: context.l10n.onboard3Body,
                    ),
                    const _LanguageStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.xl,
                  AppSizes.lg,
                  AppSizes.xl,
                  AppSizes.xl,
                ),
                child: Column(
                  children: <Widget>[
                    _PageDots(count: _pageCount, index: _page),
                    AppSizes.gapXl,
                    FilledButton(
                      onPressed: onLanguageStep
                          ? _finish
                          : () => _goTo(_page + 1),
                      child: Text(
                        onLanguageStep
                            ? context.l10n.getStarted
                            : context.l10n.actionNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selected = ref.watch(settingsProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const KoriLogo(size: 72),
          AppSizes.gapXl,
          Text(
            context.l10n.chooseLanguage,
            textAlign: TextAlign.center,
            style: context.texts.headlineSmall,
          ),
          AppSizes.gapSm,
          Text(
            context.l10n.chooseLanguageBody,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSizes.gapXxl,
          Row(
            children: <Widget>[
              Expanded(
                child: LanguageChoiceCard(
                  title: 'বাংলা',
                  subtitle: 'Bangla',
                  selected: selected == 'bn',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('bn'),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: LanguageChoiceCard(
                  title: 'English',
                  subtitle: 'ইংরেজি',
                  selected: selected == 'en',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('en'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppSizes.fast,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? context.colors.primary
                  : context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
