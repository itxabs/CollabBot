import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/linkedin_import_view_model.dart';

class LinkedInPreviewScreen extends StatelessWidget {
  const LinkedInPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LinkedInImportViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review LinkedIn Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found ${viewModel.extractedSkills.length} skills and ${viewModel.extractedExperiences.length} experience entries on your profile.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Skills Section
            if (viewModel.extractedSkills.isNotEmpty) ...[
              Text('Skills', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: viewModel.extractedSkills.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => viewModel.removeSkill(entry.key),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppColors.surface,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Experience Section
            if (viewModel.extractedExperiences.isNotEmpty) ...[
              Text('Experience', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.extractedExperiences.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final exp = viewModel.extractedExperiences[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      title: Text(exp.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(exp.organization, style: AppTextStyles.bodyMedium),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => viewModel.removeExperience(index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],

            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isLoading || (viewModel.extractedSkills.isEmpty && viewModel.extractedExperiences.isEmpty)
                    ? null
                    : () => viewModel.saveImportedData(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm & Save to Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
