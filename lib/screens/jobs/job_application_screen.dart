import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/routes.dart';
import '../../data/models/job_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/jobs_view_model.dart';

class JobApplicationScreen extends StatefulWidget {
  final JobModel job;
  const JobApplicationScreen({super.key, required this.job});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  String? _fileName;
  String? _filePath;
  bool _isSubmitted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSuccessState();
    }

    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apply for Job', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobSummary(),
                  const SizedBox(height: 32),
                  const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Full Name', user?.name ?? 'User Name'),
                  _buildReadOnlyField('Email Address', user?.userEmail ?? 'user@example.com'),
                  const SizedBox(height: 32),
                  const Text('Resume / CV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildFileUpload(),
                  const SizedBox(height: 32),
                  const Text('Cover Letter (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coverLetterController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tell us why you are a good fit...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildJobSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(widget.job.company.isNotEmpty ? widget.job.company.substring(0, 1) : 'J', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.job.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(widget.job.company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _filePath = result.files.single.path;
      });
    }
  }

  Widget _buildFileUpload() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: _fileName != null ? AppColors.tealLight.withOpacity(0.3) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, color: _fileName != null ? AppColors.tealAccent : AppColors.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(_fileName ?? 'Upload PDF Resume', style: TextStyle(color: _fileName != null ? AppColors.tealDark : AppColors.textSecondary, fontWeight: FontWeight.bold)),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.tealAccent, borderRadius: BorderRadius.circular(20)),
                child: const Text('File Selected', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your resume')));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final userId = context.read<AuthViewModel>().currentUser?.userId;
    if (userId == null) return;

    final success = await context.read<JobsViewModel>().submitApplication(
      job: widget.job, 
      userId: userId,
      coverLetter: _coverLetterController.text,
      resumePath: _filePath!,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isSubmitted = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit application. Please try again.')));
        }
      });
    }
  }

  Widget _buildSuccessState() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.tealAccent, size: 100),
              const SizedBox(height: 32),
              const Text('Application Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              const Text(
                'Your application has been successfully submitted. The company will review it and get back to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Job Details'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.myApplications),
                child: const Text('View My Applications', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
