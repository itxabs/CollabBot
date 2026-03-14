import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/custom_text_field.dart'; // Ensure this exists or use standard TextField
import '../../view_model/skills_view_model.dart';
import '../../data/models/profile_models.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedLevelId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SkillsViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Skill', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Skill Name', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Using standard TextField if CustomTextField is strict on props, checking usage:
                // Assuming standard TextFormField for simplicity to ensure form validation hooks work easily
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter skill name (e.g. Flutter)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a skill name';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                Text('Skill Level', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLevelId,
                  decoration: InputDecoration(
                    hintText: 'Select level',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  items: viewModel.levels.map((SkillLevel level) {
                    return DropdownMenuItem<String>(
                      value: level.id,
                      child: Text(level.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLevelId = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a level' : null,
                ),

                const Spacer(),
                
                if (viewModel.errorMessage != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                   ),

                PrimaryButton(
                  text: 'Save Skill',
                  isLoading: viewModel.isLoading,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      viewModel.addSkill(
                        context,
                        name: _nameController.text.trim(),
                        levelId: _selectedLevelId!,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
