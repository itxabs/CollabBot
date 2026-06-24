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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            "AI Resume Analyzer",
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: AppColors.border,
              height: 1.0,
            ),
          ),
        ),
        body: Consumer<ResumeAnalyzerViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Upload Area ---
                  if (viewModel.fileName == null && !viewModel.isLoading)
                    _buildUploadPlaceholder(context, viewModel)
                  else
                    _buildFileStatus(context, viewModel),

                  if (viewModel.score == null && !viewModel.isLoading) ...[
                    const SizedBox(height: 28),
                    _buildWhatYouGetSection(),
                  ],

                  // --- Results Section ---
                  if (viewModel.isLoading) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 5,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Analyzing ATS compatibility...",
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Scanning keywords and document structure...",
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (viewModel.score != null) ...[
                    const SizedBox(height: 24),
                    _buildScoreIndicator(viewModel.score!),
                    const SizedBox(height: 28),
                    _buildRecommendationsList(viewModel.recommendations),
                  ],
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
        color: AppColors.primary.withValues(alpha: 0.35),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        radius: const Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Upload Your Resume",
              style: AppTextStyles.h2.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Supported formats: PDF, DOCX (Max 5MB)",
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text("What you'll get:", style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
        ),
        _buildBenefitCard(
          icon: Icons.speed_outlined,
          title: "ATS Score",
          description: "See how your resume performs with applicant tracking systems",
        ),
        _buildBenefitCard(
          icon: Icons.verified_outlined,
          title: "Strength Analysis",
          description: "Discover what makes your resume stand out",
        ),
        _buildBenefitCard(
          icon: Icons.tips_and_updates_outlined,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileStatus(BuildContext context, ResumeAnalyzerViewModel viewModel) {
    final fileName = viewModel.fileName ?? "Resume.pdf";
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPdf ? const Color(0xFFFDE8E8) : const Color(0xFFE1F5FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.article,
              color: isPdf ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.isLoading ? "Analyzing ATS score..." : "Ready for analysis",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: viewModel.isLoading ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!viewModel.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              onPressed: viewModel.pickAndAnalyzeFile,
              tooltip: "Upload new file",
            ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    Color scoreColor;
    String ratingText;
    String ratingDescription;
    IconData statusIcon;

    if (score >= 80) {
      scoreColor = AppColors.success;
      ratingText = "Excellent Optimization";
      ratingDescription = "Your resume has outstanding ATS formatting and key section presence. You're ready to apply!";
      statusIcon = Icons.stars_rounded;
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
      ratingText = "Good Compatibility";
      ratingDescription = "Your resume covers most vital sections. Add more industry-relevant keywords to boost visibility.";
      statusIcon = Icons.check_circle_rounded;
    } else {
      scoreColor = AppColors.error;
      ratingText = "Needs Action";
      ratingDescription = "Your resume is missing key sections or is too short. Follow the recommendations below to fix it.";
      statusIcon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "ATS Analysis Results",
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 14,
                  backgroundColor: AppColors.divider,
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    "of 100",
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: scoreColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  ratingText,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              ratingDescription,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Action Plan (${recommendations.length})",
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Outstanding Work!",
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Your resume complies with all major ATS rules. No further actions needed.",
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.tealDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final isCritical = rec.startsWith("Add a clear");

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCritical ? Icons.error_outline : Icons.lightbulb_outline_rounded,
                        color: isCritical ? AppColors.error : AppColors.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCritical ? "Critical Fix" : "Improvement Tip",
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCritical ? AppColors.error : AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
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
