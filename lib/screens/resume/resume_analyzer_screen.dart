import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/resume_analyzer_view_model.dart';

class ResumeAnalyzerScreen extends StatelessWidget {
  const ResumeAnalyzerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResumeAnalyzerViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AI Resume Analyzer"),
          elevation: 0,
        ),
        body: Consumer<ResumeAnalyzerViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Section ---
                  const Text(
                    "Optimize Your Resume",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Upload your PDF or DOCX resume to get an instant ATS score and tailored recommendations.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- Upload Area ---
                  if (viewModel.fileName == null && !viewModel.isLoading)
                    _buildUploadPlaceholder(context, viewModel)
                  else
                    _buildFileStatus(context, viewModel),

                  const SizedBox(height: 32),

                  // --- Results Section ---
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (viewModel.errorMessage != null)
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  else if (viewModel.score != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScoreIndicator(viewModel.score!),
                            const SizedBox(height: 24),
                            _buildRecommendationsList(viewModel.recommendations),
                          ],
                        ),
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

  Widget _buildUploadPlaceholder(BuildContext context, ResumeAnalyzerViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.pickAndAnalyzeFile,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            const Text(
              "Tap to Upload Resume",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Supports PDF, DOCX (Max 5MB)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileStatus(BuildContext context, ResumeAnalyzerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.fileName ?? "Unknown File",
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!viewModel.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: viewModel.pickAndAnalyzeFile,
              tooltip: "Upload specific file again",
            ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    Color scoreColor = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                color: scoreColor,
              ),
            ),
            Text(
              "$score",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "ATS Score",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendations",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
             child: Row(children: const [
               Icon(Icons.check_circle, color: Colors.green),
               SizedBox(width: 12),
               Expanded(child: Text("Great job! Your resume looks strong."))
             ]),
           )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendations[index],
                        style: const TextStyle(fontSize: 14),
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
