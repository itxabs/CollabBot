import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/education_view_model.dart';
import 'add_education_screen.dart';

class EducationListScreen extends StatefulWidget {
  const EducationListScreen({super.key});

  @override
  State<EducationListScreen> createState() => _EducationListScreenState();
}

class _EducationListScreenState extends State<EducationListScreen> {
  late EducationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EducationViewModel();
    _viewModel.loadEducation();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _EducationListContent(),
    );
  }
}

class _EducationListContent extends StatelessWidget {
  const _EducationListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EducationViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Education', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const AddEducationScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: viewModel.loadEducation,
              child: viewModel.education.isEmpty
                  ? Center(
                      child: Text(
                        'No education added yet',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: viewModel.education.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final edu = viewModel.education[index];
                        final String startYearStr = edu.startYear != null ? edu.startYear.toString() : '';
                        final String endYearStr = edu.endYear != null ? edu.endYear.toString() : 'Present';
                        final String duration = startYearStr.isNotEmpty ? '$startYearStr - $endYearStr' : endYearStr;

                        // Formatting the Degree / Field of study display
                        String titleText = '';
                        if (edu.degree != null && edu.degree!.isNotEmpty) {
                          titleText += edu.degree!;
                        }
                        if (edu.fieldOfStudy != null && edu.fieldOfStudy!.isNotEmpty) {
                          if (titleText.isNotEmpty) titleText += ' in ';
                          titleText += edu.fieldOfStudy!;
                        }
                        if (titleText.isEmpty) {
                          titleText = 'Education';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      edu.institution,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    if (duration.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        duration,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete education',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  viewModel,
                                  edu.id,
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

  Future<void> _confirmDelete(
    BuildContext context,
    EducationViewModel viewModel,
    String educationId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete education?'),
        content: const Text(
          'This education will be removed from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await viewModel.deleteEducation(context, educationId);
    }
  }
}
