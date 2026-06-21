import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/education_view_model.dart';

class AddEducationScreen extends StatefulWidget {
  const AddEducationScreen({super.key});

  @override
  State<AddEducationScreen> createState() => _AddEducationScreenState();
}

class _AddEducationScreenState extends State<AddEducationScreen> {
  final TextEditingController _instController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _instController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EducationViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Education', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLabel('Institution / School'),
                      _buildTextField(_instController, 'Enter school or university name', isRequired: true),

                      const SizedBox(height: 16),
                      _buildLabel('Degree (Optional)'),
                      _buildTextField(_degreeController, 'e.g. Bachelor\'s, Master\'s'),

                      const SizedBox(height: 16),
                      _buildLabel('Field of Study (Optional)'),
                      _buildTextField(_fieldController, 'e.g. Computer Science'),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Start Date'),
                                GestureDetector(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _startDate == null ? 'Select Date' : DateFormat('MMM yyyy').format(_startDate!),
                                      style: _startDate == null ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('End Date (Optional)'),
                                GestureDetector(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _endDate == null ? 'Present' : DateFormat('MMM yyyy').format(_endDate!),
                                      style: _endDate == null ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    PrimaryButton(
                      text: 'Save Education',
                      isLoading: viewModel.isLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_startDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select start date')),
                            );
                            return;
                          }
                          if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('End date cannot be before start date')),
                            );
                            return;
                          }
                          viewModel.addEducation(
                            context,
                            institution: _instController.text.trim(),
                            degree: _degreeController.text.trim().isEmpty ? null : _degreeController.text.trim(),
                            fieldOfStudy: _fieldController.text.trim().isEmpty ? null : _fieldController.text.trim(),
                            startYear: _startDate!.year,
                            endYear: _endDate?.year,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
