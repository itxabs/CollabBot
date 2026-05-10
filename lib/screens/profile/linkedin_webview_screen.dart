import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/linkedin_import_view_model.dart';
import '../../data/models/profile_models.dart';
import 'linkedin_preview_screen.dart';

class LinkedInWebViewScreen extends StatefulWidget {
  final String initialUrl;
  const LinkedInWebViewScreen({super.key, this.initialUrl = 'https://www.linkedin.com/login'});

  @override
  State<LinkedInWebViewScreen> createState() => _LinkedInWebViewScreenState();
}

class _LinkedInWebViewScreenState extends State<LinkedInWebViewScreen> {
  late final WebViewController _controller;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isPageLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isPageLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'LinkedInExtractor',
        onMessageReceived: (JavaScriptMessage message) {
          _handleExtractedData(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _handleExtractedData(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<String> skills = List<String>.from(data['skills'] ?? []);
      
      final List<Experience> experiences = (data['experiences'] as List? ?? []).map<Experience>((e) {
        // Parse dates safely
        DateTime startDate = DateTime.now();
        DateTime? endDate;
        
        return Experience(
          id: '', // Temporary
          userId: '', // Temporary
          title: e['role'] ?? 'Unknown Role',
          organization: e['company'] ?? 'Unknown Company',
          startDate: startDate,
          endDate: endDate,
          description: '',
        );
      }).toList();

      final viewModel = Provider.of<LinkedInImportViewModel>(context, listen: false);
      viewModel.setExtractedData(skills, experiences);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: viewModel,
            child: const LinkedInPreviewScreen(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to parse LinkedIn data: $e')),
      );
    }
  }

  void _extractData() async {
    const String script = """
      (function() {
        const data = {
          skills: [],
          experiences: []
        };

        function findSectionByText(text) {
          const allElements = document.querySelectorAll('h1, h2, h3, h4, h5, span, strong, div');
          for (let el of allElements) {
            if (el.innerText.trim() === text || el.innerText.trim().toLowerCase() === text.toLowerCase()) {
              // Found a header! Go up to find the container
              let curr = el;
              for (let i = 0; i < 5; i++) {
                if (curr.parentElement) {
                  curr = curr.parentElement;
                  if (curr.tagName === 'SECTION' || curr.classList.contains('artdeco-card')) return curr;
                }
              }
              return curr; // Fallback
            }
          }
          return null;
        }

        // 1. Skills
        const skillsSection = findSectionByText('Skills') || findSectionByText('Competencias');
        if (skillsSection) {
          const spans = skillsSection.querySelectorAll('span[aria-hidden="true"]');
          spans.forEach(s => {
            const val = s.innerText.trim();
            if (val && val.length > 1 && val.length < 60 && !val.includes('·') && !val.toLowerCase().includes('skills')) {
              if (!data.skills.includes(val)) data.skills.push(val);
            }
          });
        }

        // 2. Experience
        const expSection = findSectionByText('Experience') || findSectionByText('Experiencia');
        if (expSection) {
          const items = expSection.querySelectorAll('li');
          items.forEach(item => {
            const spans = Array.from(item.querySelectorAll('span[aria-hidden="true"]'))
                               .map(s => s.innerText.trim())
                               .filter(t => t.length > 0);
            
            if (spans.length >= 1) {
              // If it's a nested structure, the first span might be the role, or the company if multiple roles exist
              // We'll take the first two meaningful spans
              const role = spans[0];
              const company = spans.length > 1 ? spans[1].split('·')[0].trim() : 'LinkedIn Profile';
              
              if (role.length < 100 && !role.toLowerCase().includes('experience')) {
                 data.experiences.push({ role, company });
              }
            }
          });
        }

        LinkedInExtractor.postMessage(JSON.stringify(data));
      })();
    """;

    await _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Profile'),
        actions: [
          if (!_isPageLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isPageLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _extractData,
        label: const Text('Extract Data'),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
