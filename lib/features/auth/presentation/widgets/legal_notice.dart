import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/services/link_service.dart';

/// The terms + privacy line under the sign-in button.
///
/// It is assembled from four separate strings because Bangla needs a trailing
/// verb after both links, which English does not have — a single template
/// string could not satisfy both languages.
class LegalNotice extends StatefulWidget {
  const LegalNotice({super.key});

  @override
  State<LegalNotice> createState() => _LegalNoticeState();
}

class _LegalNoticeState extends State<LegalNotice> {
  // Recognizers are created once, not per build: a TapGestureRecognizer built
  // inside build() leaks on every rebuild.
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => LinkService.open(AppConfig.termsUrl);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => LinkService.open(AppConfig.privacyPolicyUrl);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = context.texts.bodySmall;
    final TextStyle? link = base?.copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
    );
    final String suffix = context.l10n.legalSuffix;

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: '${context.l10n.legalPrefix} '),
          TextSpan(
            text: context.l10n.termsOfService,
            style: link,
            recognizer: _termsTap,
          ),
          TextSpan(text: ' ${context.l10n.and} '),
          TextSpan(
            text: context.l10n.privacyPolicy,
            style: link,
            recognizer: _privacyTap,
          ),
          if (suffix.isNotEmpty) TextSpan(text: ' $suffix'),
        ],
      ),
      textAlign: TextAlign.center,
      style: base,
    );
  }
}
