import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/navigation/premium_bottom_nav_bar.dart';
import '../../providers/app_state_provider.dart';
import '../../app/routes.dart';
import '../../services/voice_alarm_service.dart';
import '../shared/create_alarm_screen.dart';
import 'commuter_alarms_screen.dart';
import 'commuter_map_screen.dart';

/// Keeps visited commuter tabs alive so the map is not recreated on tab changes.
class CommuterShell extends StatefulWidget {
  const CommuterShell({super.key});

  @override
  State<CommuterShell> createState() => _CommuterShellState();
}

class _CommuterShellState extends State<CommuterShell> {
  late final AppStateProvider _appState;
  final VoiceAlarmService _voiceAlarmService = VoiceAlarmService();
  bool _isCapturingVoice = false;
  bool _isParsingVoice = false;
  String _liveTranscript = '';

  final Set<int> _initializedTabs = {0};

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppStateProvider>();
    _appState.registerAlarmTriggerCallback(_onAlarmTriggered);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState.startLocationTracking();
    });
  }

  @override
  void dispose() {
    _appState.unregisterAlarmTriggerCallback();
    unawaited(_voiceAlarmService.cancel());
    super.dispose();
  }

  void _onAlarmTriggered() {
    if (!mounted) return;
    final alarm = _appState.triggeredAlarm;
    if (alarm == null) return;

    Navigator.of(context)
        .pushNamed(AppRoutes.alarmTrigger, arguments: alarm)
        .then((_) => _appState.acknowledgeTriggerNavigation());
  }

  Future<void> _onVoiceAlarmPressed() async {
    if (_isCapturingVoice || _isParsingVoice) return;

    setState(() {
      _isCapturingVoice = true;
      _isParsingVoice = false;
      _liveTranscript = '';
    });

    try {
      final transcript = await _voiceAlarmService.listenOnce(
        onTranscriptChanged: (text) {
          if (!mounted || !_isCapturingVoice) return;
          setState(() => _liveTranscript = text);
        },
      );
      if (!mounted) return;

      if (transcript == null || transcript.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No voice input detected. Try again.')),
        );
        return;
      }

      setState(() {
        _isCapturingVoice = false;
        _isParsingVoice = true;
        _liveTranscript = transcript.trim();
      });

      VoiceAlarmDraft draft;
      try {
        draft = await _voiceAlarmService.parseAlarmDraftWithAi(transcript);
      } on VoiceAlarmParseException catch (e) {
        draft = _voiceAlarmService.parseAlarmDraft(transcript);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }

      if (!mounted) return;
      showCreateAlarmBottomSheet(context, initialDraft: draft);
    } on VoiceCaptureException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice capture failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted && (_isCapturingVoice || _isParsingVoice)) {
        setState(() {
          _isCapturingVoice = false;
          _isParsingVoice = false;
          _liveTranscript = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, int>(
      selector: (_, state) => state.commuterTabIndex,
      builder: (context, tabIndex, _) {
        _initializedTabs.add(tabIndex);

        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final navBottomPadding = bottomInset > 0 ? bottomInset * 0.55 : 10.0;
        final transcriptBottomOffset = 62.0 + navBottomPadding + 8;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(
                index: tabIndex,
                children: [
                  _initializedTabs.contains(0)
                      ? CommuterAlarmsScreen(isActiveTab: tabIndex == 0)
                      : const SizedBox.shrink(),
                  _initializedTabs.contains(1)
                      ? const CommuterMapScreen()
                      : const SizedBox.shrink(),
                ],
              ),
              if (_isCapturingVoice && _liveTranscript.trim().isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: transcriptBottomOffset,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CupertinoColors.systemRed.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          _liveTranscript,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: PremiumBottomNavBar(
            currentIndex: tabIndex,
            onTap: (i) => _appState.setCommuterTab(i),
            onExtraButtonTap: tabIndex == 1 ? _onVoiceAlarmPressed : null,
            extraButtonIcon: _isCapturingVoice || _isParsingVoice
                ? CupertinoIcons.mic_fill
                : CupertinoIcons.mic,
            extraButtonLabel: _isParsingVoice
                ? 'Parsing'
                : _isCapturingVoice
                ? 'Listening'
                : 'Voice',
            extraButtonIconColor: _isCapturingVoice || _isParsingVoice
                ? CupertinoColors.systemRed
                : null,
            items: const [
              PremiumBottomNavItem(icon: CupertinoIcons.alarm, label: 'Alarms'),
              PremiumBottomNavItem(icon: CupertinoIcons.map, label: 'Map'),
            ],
          ),
        );
      },
    );
  }
}
