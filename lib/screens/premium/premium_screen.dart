import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PREMIUM MEMBERSHIP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gold Gradient Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2005), Color(0xFF141926)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.12),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.premiumGoldGradient,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'YS SCORE 11 PRO',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Professional Grade Cricket Analytics',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Pricing Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹5', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(' / month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Features Checklist
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRO PRIVILEGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8)),
                  const SizedBox(height: 14),
                  _buildFeatureRow('AI Win Predictor (Full In-Play Probabilities)'),
                  _buildFeatureRow('Advanced Tournament Analytics & NRR Modeler'),
                  _buildFeatureRow('In-depth Player Career Strike Rate & Economy Charts'),
                  _buildFeatureRow('Cloud Backup & Sync (PostgreSQL Ready)'),
                  _buildFeatureRow('Export Match Scorecards & Certificates'),
                  _buildFeatureRow('Dedicated Priority Customer Support'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subscription Button
            if (auth.isPremium)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text('PRO MEMBERSHIP ACTIVE', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    auth.upgradeToPremium();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgraded to YS SCORE 11 PRO (Ready for Google Play Billing)!')),
                    );
                  },
                  child: const Text('SUBSCRIBE NOW (₹5/MONTH)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8)),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Architecture ready for Google Play In-App Subscriptions & server-side receipt verification.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}
