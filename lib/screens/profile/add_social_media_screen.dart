import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/social_media_view_model.dart';

class AddSocialMediaScreen extends StatefulWidget {
  const AddSocialMediaScreen({super.key});

  @override
  State<AddSocialMediaScreen> createState() => _AddSocialMediaScreenState();
}

class _AddSocialMediaScreenState extends State<AddSocialMediaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialMediaViewModel>().clearForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SocialMediaViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Social Link', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel('Platform'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: viewModel.selectedPlatform,
                      hint: const Text('Select Platform'),
                      isExpanded: true,
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: viewModel.platforms.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (value) => viewModel.selectedPlatform = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please select a platform';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLabel('URL'),
                TextFormField(
                  controller: viewModel.urlController,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a URL';
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Please enter a valid link starting with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                PrimaryButton(
                  text: 'Save Social Link',
                  isLoading: viewModel.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await viewModel.addSocialLink(context);
                      if (viewModel.errorMessage == null && context.mounted) {
                        Navigator.pop(context);
                      }
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
