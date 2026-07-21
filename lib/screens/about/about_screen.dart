// lib/screens/about/about_screen.dart
import 'package:flutter/material.dart';
import 'package:plantmitra_1/constants/app_assets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _secondaryText = Color(0xFF69806E);

  void _showDocument(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(height: 1.5)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('About Jarvis Green'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF5), Color(0xFFEAF7EC)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          children: [
            _BrandCard(),
            const SizedBox(height: 18),
            const _SectionTitle('Our mission'),
            const SizedBox(height: 9),
            const _InformationCard(
              icon: Icons.eco_outlined,
              title: 'Grow a greener community',
              text:
                  'Jarvis Green helps plant lovers discover, share and responsibly exchange plants while building meaningful local connections.',
            ),
            const SizedBox(height: 18),
            const _SectionTitle('What you can do'),
            const SizedBox(height: 9),
            const _FeatureGrid(),
            const SizedBox(height: 18),
            const _SectionTitle('Information'),
            const SizedBox(height: 9),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy summary',
                  subtitle: 'How your information is used',
                  onTap: () => _showDocument(
                    context,
                    'Privacy summary',
                    'Jarvis Green stores the account information, plant listings, favorites, chats, reports and notification preferences required to provide the app. Private account information is protected by Firebase Authentication and Firestore security rules. Before publishing publicly, replace this summary with your final reviewed Privacy Policy and official web link.',
                  ),
                ),
                _MenuTile(
                  icon: Icons.description_outlined,
                  title: 'Community guidelines',
                  subtitle: 'Keep listings and conversations safe',
                  onTap: () => _showDocument(
                    context,
                    'Community guidelines',
                    'Share accurate plant information, communicate respectfully, do not post prohibited or unsafe plants, and report misleading or inappropriate listings. Users remain responsible for complying with local laws and regulations.',
                  ),
                ),
                _MenuTile(
                  icon: Icons.code_rounded,
                  title: 'Open-source licenses',
                  subtitle: 'Libraries used by Jarvis Green',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Jarvis Green',
                    applicationVersion: '1.0.0 (1)',
                    applicationIcon: const Icon(
                      Icons.eco_rounded,
                      color: _green,
                      size: 44,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Made with care for plant lovers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0ECE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12174D2B),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 126,
            height: 126,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD7EDD9), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.logo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF2E7D32),
                  size: 62,
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Jarvis Green',
            style: TextStyle(
              color: Color(0xFF174D2B),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Grow  •  Share  •  Connect',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Version 1.0.0 (1)',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF174D2B),
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF174D2B), Color(0xFF2E7D32)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const features = <(IconData, String)>[
      (Icons.local_florist_outlined, 'Discover plants'),
      (Icons.volunteer_activism_outlined, 'Share locally'),
      (Icons.chat_bubble_outline_rounded, 'Plant-specific chat'),
      (Icons.favorite_outline_rounded, 'Save favorites'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: features
              .map(
                (feature) => Container(
                  width: width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E9E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(feature.$1, color: const Color(0xFF2E7D32)),
                      const SizedBox(height: 9),
                      Text(
                        feature.$2,
                        style: const TextStyle(
                          color: Color(0xFF263B2B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE0E9E1)),
    ),
    child: Column(children: children),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF2E7D32), size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF263B2B),
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Color(0xFF69806E), fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
