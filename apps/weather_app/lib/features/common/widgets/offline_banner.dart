// OfflineBanner: persistent, warning-tinted, on all screens above content
// (design §4). Announces via polite live region (Announcer, not scattered).

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/announcer.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class OfflineBanner extends StatefulWidget {
  /// e.g. "12:04" (location-local) or "2 h ago" — the caller formats.
  final String detail;

  const OfflineBanner({super.key, required this.detail});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  @override
  void initState() {
    super.initState();
    // Announce once on appearance (polite live region, design §4).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AppLocalizations strings = AppLocalizations.of(context);
      Announcer.announcePolite(strings.offlineBannerAnnouncement(widget.detail));
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
        color: DesignTokens.warning(context).withValues(alpha: 0.15),
        child: Row(
          children: <Widget>[
            Icon(Icons.wifi_off,
                size: 18, color: DesignTokens.warning(context)),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                strings.offlineBanner(widget.detail),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
