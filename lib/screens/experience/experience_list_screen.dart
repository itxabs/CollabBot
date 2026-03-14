import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/experience_view_model.dart';
import 'add_experience_screen.dart';

class ExperienceListScreen extends StatefulWidget {
  const ExperienceListScreen({super.key});

  @override
  State<ExperienceListScreen> createState() => _ExperienceListScreenState();
}

class _ExperienceListScreenState extends State<ExperienceListScreen> {
  late ExperienceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExperienceViewModel();
    _viewModel.loadExperiences();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _ExperienceListContent(),
    );
  }
}

class _ExperienceListContent extends StatelessWidget {
  const _ExperienceListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExperienceViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Experience', style: AppTextStyles.h3),
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
                    child: const AddExperienceScreen(),
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
              onRefresh: viewModel.loadExperiences,
              child: viewModel.experiences.isEmpty
                  ? Center(
                      child: Text(
                        'No experience added yet',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: viewModel.experiences.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final exp = viewModel.experiences[index];
                        final String startDate = DateFormat('MMM yyyy').format(exp.startDate);
                        final String endDate = exp.endDate != null 
                            ? DateFormat('MMM yyyy').format(exp.endDate!) 
                            : 'Present';

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
                                 child: const Icon(Icons.work_outline, color: AppColors.primary, size: 20),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(exp.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                     const SizedBox(height: 4),
                                     Text(exp.organization, style: AppTextStyles.bodyMedium),
                                     const SizedBox(height: 4),
                                     Text('$startDate - $endDate', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                     if (exp.description != null && exp.description!.isNotEmpty) ...[
                                       const SizedBox(height: 8),
                                       Text(
                                         exp.description!,
                                         style: AppTextStyles.bodySmall,
                                         maxLines: 2,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ],
                                   ],
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
}
