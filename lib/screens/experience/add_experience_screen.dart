import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/experience_view_model.dart';

class AddExperienceScreen extends StatefulWidget {
  const AddExperienceScreen({super.key});

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _orgController.dispose();
    _titleController.dispose();
    _descController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExperienceViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Experience', style: AppTextStyles.h3),
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
                 _buildLabel('Organization'),
                 _buildTextField(_orgController, 'Enter organization name'),
                 
                 const SizedBox(height: 16),
                 _buildLabel('Job Title'),
                 _buildTextField(_titleController, 'Enter job title'),
                 
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
                 
                 const SizedBox(height: 16),
                 _buildLabel('Description (Optional)'),
                 _buildTextField(_descController, 'Enter description', maxLines: 4),

                 const SizedBox(height: 32),
                 
                 if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),

                 PrimaryButton(
                   text: 'Save Experience',
                   isLoading: viewModel.isLoading,
                   onPressed: () {
                     if (_formKey.currentState!.validate()) {
                       if (_startDate == null) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start date')));
                         return;
                       }
                       
                       viewModel.addExperience(
                         context,
                         organization: _orgController.text.trim(),
                         title: _titleController.text.trim(),
                         description: _descController.text.trim(),
                         startDate: _startDate!,
                         endDate: _endDate,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      ),
      validator: (value) {
        if (maxLines == 1 && (value == null || value.isEmpty)) return 'This field is required'; // Simple required check for single lines
        return null;
      },
    );
  }
}
