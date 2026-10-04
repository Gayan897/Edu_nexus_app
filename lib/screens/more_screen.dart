import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../i18n/strings.dart';
import 'login_screen.dart';
import 'al_advisor_screen.dart';
import 'circulars_screen.dart';
import 'ews_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            expandedHeight: 120,
            backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                alignment: Alignment.bottomLeft,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SAMSStrings.navMore,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        provider.user?.name ?? '',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Complete Profile Card ─────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              provider.studentName.isNotEmpty
                                  ? provider.studentName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.studentName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    provider.studentId.isNotEmpty ? provider.studentId : 'ID: N/A',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SAMSStrings.grade,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '${provider.studentGrade.isNotEmpty ? provider.studentGrade : "—"} · Class ${provider.studentClass.isNotEmpty ? provider.studentClass : "—"}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Role',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                provider.isParent ? 'Parent / Guardian' : 'Enrolled Student',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Section: Academic Tools ───────────────────────────────
                const _SectionLabel('Academic Tools'),
                _MenuCard(
                  icon: Icons.warning_amber_rounded,
                  color: SAMSColors.ewsWarning,
                  title: SAMSStrings.earlyWarning,
                  subtitle: 'Academic health guidance & alerts',
                  isDark: isDark,
                  onTap: () => Navigator.push(context, _route(const EwsScreen())),
                ),
                _MenuCard(
                  icon: Icons.school_rounded,
                  color: SAMSColors.primary,
                  title: SAMSStrings.alAdvisor,
                  subtitle: 'O/L → A/L stream predictor & Z-Score',
                  isDark: isDark,
                  onTap: () => Navigator.push(context, _route(const AlAdvisorScreen())),
                ),
                _MenuCard(
                  icon: Icons.campaign_rounded,
                  color: SAMSColors.secondary,
                  title: SAMSStrings.circulars,
                  subtitle: 'School announcements & notices',
                  isDark: isDark,
                  onTap: () => Navigator.push(context, _route(const CircularsScreen())),
                ),
                const SizedBox(height: 16),

                // ── Section: Settings ─────────────────────────────────────
                _SectionLabel(SAMSStrings.settings),

                // Language
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SAMSColors.primaryLight.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.language_rounded, color: SAMSColors.primaryLight, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            SAMSStrings.language,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _LangBtn(lang: AppLanguage.english, label: 'English', provider: provider),
                          const SizedBox(width: 8),
                          _LangBtn(lang: AppLanguage.sinhala, label: 'සිංහල', provider: provider),
                          const SizedBox(width: 8),
                          _LangBtn(lang: AppLanguage.tamil, label: 'தமிழ்', provider: provider),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dark mode toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dark_mode_rounded, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        SAMSStrings.darkMode,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Switch(
                        value: isDark,
                        onChanged: (_) => provider.toggleTheme(),
                        activeThumbColor: SAMSColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Logout ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          _route(const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18, color: SAMSColors.absent),
                    label: Text(SAMSStrings.logout, style: const TextStyle(color: SAMSColors.absent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SAMSColors.absent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Text(
                    'SAMS v1.0.0 · Smart Academic Management System\nSri Lanka Government Schools',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  PageRoute _route(Widget screen) => MaterialPageRoute(builder: (_) => screen);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: SAMSColors.primaryLight,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub),
          ],
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final AppLanguage lang;
  final String label;
  final AppProvider provider;

  const _LangBtn({required this.lang, required this.label, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.language == lang;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setLanguage(lang),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? SAMSColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? SAMSColors.primary : SAMSColors.bgDarkSurface,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? Colors.white : SAMSColors.textDarkSub,
            ),
          ),
        ),
      ),
    );
  }
}
