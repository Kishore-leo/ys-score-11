import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../providers/scoring_provider.dart';
import '../../services/ai_predictor_service.dart';

class AiPredictionScreen extends StatefulWidget {
  const AiPredictionScreen({super.key});

  @override
  State<AiPredictionScreen> createState() => _AiPredictionScreenState();
}

class _AiPredictionScreenState extends State<AiPredictionScreen> {
  CricketMatch? _selectedMatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scoring = context.read<ScoringProvider>();
      if (scoring.activeMatch != null) {
        setState(() => _selectedMatch = scoring.activeMatch);
      } else if (scoring.matches.isNotEmpty) {
        setState(() => _selectedMatch = scoring.matches.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scoring = context.watch<ScoringProvider>();
    final allMatches = scoring.matches;

    final prediction = _selectedMatch != null
        ? AiPredictorService.predictWinProbability(_selectedMatch!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI MATCH PREDICTOR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AIML Project Badge Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AIML FINAL-YEAR PROJECT MODULE', style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                        Text('Dynamic In-Play Win Probability Engine', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Select Match Dropdown
            const Text('Select Cricket Match', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (allMatches.isNotEmpty)
              DropdownButtonFormField<CricketMatch>(
                value: _selectedMatch,
                dropdownColor: AppColors.cardLight,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                items: allMatches.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text('${m.name} (${m.teamA.name} vs ${m.teamB.name})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMatch = val);
                },
              )
            else
              const Text('No matches found. Create a match to predict win probabilities.', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),

            if (prediction != null && _selectedMatch != null) ...[
              // Probability Gauge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('REAL-TIME WIN PROBABILITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
                    const SizedBox(height: 20),

                    // Probability Dual Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 22,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (prediction.teamAProbability * 10).round().clamp(1, 999),
                              child: Container(color: AppColors.accent),
                            ),
                            Expanded(
                              flex: (prediction.teamBProbability * 10).round().clamp(1, 999),
                              child: Container(color: AppColors.electricBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Team Percentages
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedMatch!.teamA.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            Text(
                              '${prediction.teamAProbability.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.accent),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_selectedMatch!.teamB.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            Text(
                              '${prediction.teamBProbability.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.electricBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Natural Language Explanation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 18),
                        SizedBox(width: 8),
                        Text('AI PREDICTION ANALYSIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.gold, letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      prediction.explanation,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Key Influencing Factors
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KEY CONTRIBUTING FACTORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    ...prediction.keyFactors.map((f) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Backend Python Integration Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BACKEND INTEGRATION READY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text(
                      'Ready to connect to Python + FastAPI + Scikit-Learn at /api/ml/predict with Logistic Regression & Random Forest models trained on match state matrices.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
