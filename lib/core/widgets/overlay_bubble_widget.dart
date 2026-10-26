import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Entry point widget for the floating overlay window.
///
/// Operates in two states:
/// 1. Compact: A sleek floating circular bubble (72x72) that can be dragged
///    anywhere across the screen.
/// 2. Expanded: A modern quick-action card (280x260) with fast shortcuts to
///    add an expense, add income, or jump directly into Poisa.
class PoisaOverlayApp extends StatelessWidget {
  const PoisaOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: PoisaOverlayBubble(),
      ),
    );
  }
}

class PoisaOverlayBubble extends StatefulWidget {
  const PoisaOverlayBubble({super.key});

  @override
  State<PoisaOverlayBubble> createState() => _PoisaOverlayBubbleState();
}

class _PoisaOverlayBubbleState extends State<PoisaOverlayBubble> {
  bool _isExpanded = false;

  static const int _bubbleSize = 72;
  static const int _expandedWidth = 280;
  static const int _expandedHeight = 260;

  static const MethodChannel _appChannel =
      MethodChannel('com.kori.moneytracker/overlay');

  Future<void> _expand() async {
    await FlutterOverlayWindow.resizeOverlay(_expandedWidth, _expandedHeight, false);
    if (mounted) {
      setState(() => _isExpanded = true);
    }
  }

  Future<void> _collapse() async {
    await FlutterOverlayWindow.resizeOverlay(_bubbleSize, _bubbleSize, true);
    if (mounted) {
      setState(() => _isExpanded = false);
    }
  }

  Future<void> _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Brings Poisa to the front through MainActivity's overlay channel.
  /// `poisa://add/<type>` opens the transaction editor, `poisa://open` just
  /// the app.
  Future<void> _triggerAction(String action) async {
    await _collapse();
    final String uri = action == 'open' ? 'poisa://open' : 'poisa://add/$action';
    try {
      await _appChannel.invokeMethod<bool>('openApp', <String, String>{
        'uri': uri,
      });
    } catch (error) {
      debugPrint('PoisaOverlayBubble: openApp failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return _buildCompactBubble();
    }
    return _buildExpandedCard();
  }

  /// Compact floating coin / bubble
  Widget _buildCompactBubble() {
    return Center(
      child: GestureDetector(
        onTap: _expand,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF014F3E), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF34D399).withOpacity(0.8),
              width: 2.2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x3310B981),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '৳',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Expanded quick actions modal
  Widget _buildExpandedCard() {
    return Center(
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF059669).withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 24,
              offset: Offset(0, 8),
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF014F3E),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '৳',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Poisa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Minimize to bubble
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.remove, color: Colors.white70, size: 20),
                  onPressed: _collapse,
                  tooltip: 'Minimize',
                ),
                const SizedBox(width: 4),
                // Close completely
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: _closeOverlay,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action: Add Expense
            _ActionButton(
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFF450A0A),
              title: 'খরচ লিখুন (Expense)',
              subtitle: 'টাকা খরচ যোগ করুন',
              onTap: () => _triggerAction('expense'),
            ),
            const SizedBox(height: 8),

            // Action: Add Income
            _ActionButton(
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFF064E3B),
              title: 'আয় লিখুন (Income)',
              subtitle: 'টাকা জমা যোগ করুন',
              onTap: () => _triggerAction('income'),
            ),
            const SizedBox(height: 8),

            // Action: Open Main App
            InkWell(
              onTap: () => _triggerAction('open'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.launch_rounded, size: 15, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'অ্যাপে যান (Open Poisa)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
