import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/jobs_view_model.dart';
import '../../data/models/job_model.dart';
import 'package:uuid/uuid.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _skillsController = TextEditingController();
  String _selectedType = 'Full-time';
  DateTime? _selectedDeadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Post a Job', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Job Basics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Job Title', _titleController, 'e.g. Junior Flutter Developer'),
              _buildTextField('Company Name', _companyController, 'e.g. Tech Solutions Inc.'),
              _buildTextField('Location', _locationController, 'e.g. Remote or City, Country'),
              _buildTextField('Salary Range', _salaryController, 'e.g. \$40k - \$60k'),
              
              const Text('Employment Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ['Full-time', 'Part-time', 'Internship', 'Contract'].map((t) => 
                  DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 24),

              const Text('Application Deadline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _selectedDeadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDeadline == null ? 'Select Deadline' : _selectedDeadline!.toLocal().toString().split(' ')[0],
                        style: TextStyle(color: _selectedDeadline == null ? AppColors.textSecondary : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Requirements & Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Required Skills', _skillsController, 'e.g. Flutter, Dart, Firebase (comma separated)'),
              _buildTextField('Key Requirements', _requirementsController, 'e.g. 1+ year exp, CS Degree (comma separated)'),
              
              const Text('Job Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField('', _descriptionController, 'Describe the role...', maxLines: 4),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit for Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
          ),
        ],
      ),
    );
  }

  void _submitJob() async {
    if (_formKey.currentState!.validate()) {
      final authVm = context.read<AuthViewModel>();
      final jobsVm = context.read<JobsViewModel>();
      
      final skills = _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final requirements = _requirementsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final job = JobModel(
        id: const Uuid().v4(),
        creatorId: authVm.currentUser?.userId ?? '',
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        salaryRange: _salaryController.text.trim(),
        employmentType: _selectedType,
        experienceLevel: 'Junior',
        requirements: requirements,
        skills: skills,
        createdAt: DateTime.now(),
        deadline: _selectedDeadline,
        status: 'Pending',
        isRemote: _locationController.text.toLowerCase().contains('remote'),
      );

      final success = await jobsVm.createJob(job);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job post submitted! It will appear after admin approval.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit job. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
