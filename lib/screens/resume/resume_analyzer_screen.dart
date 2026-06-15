import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../view_model/resume_analyzer_view_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';

class ResumeAnalyzerScreen extends StatelessWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResumeAnalyzerViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AI Resume Analyzer"),
          elevation: 0,
        ),
        body: Consumer<ResumeAnalyzerViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // --- Upload Area ---
                  if (viewModel.fileName == null && !viewModel.isLoading)
                    _buildUploadPlaceholder(context, viewModel)
                  else
                    _buildFileStatus(context, viewModel),

                  if (viewModel.score == null && !viewModel.isLoading) ...[
                    const SizedBox(height: 32),
                    _buildWhatYouGetSection(),
                  ],

                  const SizedBox(height: 32),

                  // --- Results Section ---
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (viewModel.errorMessage != null)
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  else if (viewModel.score != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScoreIndicator(viewModel.score!),
                            const SizedBox(height: 24),
                            _buildRecommendationsList(viewModel.recommendations),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context, ResumeAnalyzerViewModel viewModel) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: AppColors.primary.withOpacity(0.3),
        strokeWidth: 2,
        dashPattern: const [6, 4],
        radius: const Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.file_upload_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text("Upload Your Resume", style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              "Supported formats: PDF, DOCX (Max 5MB)",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: PrimaryButton(
                text: 'Choose File',
                onPressed: viewModel.pickAndAnalyzeFile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatYouGetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What you'll get:", style: AppTextStyles.h3),
        const SizedBox(height: 16),
        _buildBenefitCard(
          icon: Icons.trending_up,
          title: "ATS Score",
          description: "See how your resume performs with applicant tracking systems",
        ),
        _buildBenefitCard(
          icon: Icons.check_circle_outline,
          title: "Strength Analysis",
          description: "Discover what makes your resume stand out",
        ),
        _buildBenefitCard(
          icon: Icons.info_outline,
          title: "Improvement Tips",
          description: "Get actionable suggestions to boost your score",
        ),
      ],
    );
  }

  Widget _buildBenefitCard({required IconData icon, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileStatus(BuildContext context, ResumeAnalyzerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.fileName ?? "Unknown File",
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!viewModel.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: viewModel.pickAndAnalyzeFile,
              tooltip: "Upload specific file again",
            ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    Color scoreColor = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                color: scoreColor,
              ),
            ),
            Text(
              "$score",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "ATS Score",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendations",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
             child: Row(children: [
               const Icon(Icons.check_circle, color: Colors.green),
               const SizedBox(width: 12),
               Expanded(child: Text("Great job! Your resume looks strong.")),
             ]),
           )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendations[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
