import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accent.withOpacity(0.2),
                    child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Young Storms Member',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.emailOrMobile ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: auth.isPremium ? AppColors.gold.withOpacity(0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: auth.isPremium ? AppColors.gold : AppColors.border),
                    ),
                    child: Text(
                      auth.isPremium ? 'PRO MEMBER' : 'FREE PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: auth.isPremium ? AppColors.gold : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Settings & Info
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.accent),
                    title: const Text('Brand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Text('Young Storms', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.cyan),
                    title: const Text('Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Text('YS SCORE 11 v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.code_rounded, color: AppColors.amber),
                    title: const Text('AIML Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Text('Final-Year Module', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
