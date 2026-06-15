import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy Policy', style: AppTextStyles.h2),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppTextStyles.h1.copyWith(fontSize: 24, height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: June 15, 2026',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildParagraph(
              'This Privacy Policy applies to the CollabBot mobile application and any related services (collectively, the "Application") operated by Abdul Samad (the "Service Provider").',
            ),
            _buildParagraph(
              'By accessing or using the Application, you agree to the collection, use, and disclosure of information as described in this Privacy Policy.',
            ),
            
            _buildSection('Information We Collect'),
            _buildSubSection('Information You Provide'),
            _buildParagraph('To use certain features of the Application, you may provide:'),
            _buildBulletPoint('Full Name'),
            _buildBulletPoint('Email Address'),
            _buildBulletPoint('Date of Birth (DOB)'),
            _buildBulletPoint('Profile Photo'),
            _buildBulletPoint('Skills and Professional Information'),
            _buildBulletPoint('Education Information'),
            _buildBulletPoint('Employment Information'),
            _buildBulletPoint('Location Information (if enabled by you)'),
            _buildBulletPoint('Messages, posts, comments, project information, and other content you create or share within the Application'),
            _buildBulletPoint('Communications sent to the Service Provider'),

            _buildSubSection('Automatically Collected Information'),
            _buildParagraph('When you use the Application, certain information may be collected automatically, including:'),
            _buildBulletPoint('Internet Protocol (IP) address'),
            _buildBulletPoint('Device type and device identifiers'),
            _buildBulletPoint('Mobile operating system and version'),
            _buildBulletPoint('Application usage data'),
            _buildBulletPoint('Pages or screens viewed'),
            _buildBulletPoint('Date and time of access'),
            _buildBulletPoint('Session duration'),
            _buildBulletPoint('Crash reports and diagnostic information'),
            _buildBulletPoint('Network and performance information'),

            _buildSection('Artificial Intelligence Features'),
            _buildParagraph('CollabBot uses Artificial Intelligence (AI) technologies to provide features such as:'),
            _buildBulletPoint('AI-powered assistance'),
            _buildBulletPoint('Content recommendations'),
            _buildBulletPoint('Collaboration support'),
            _buildBulletPoint('Automated responses and suggestions'),
            _buildParagraph(
              'User prompts, messages, uploaded content, and interactions with AI features may be processed to provide these services.',
            ),
            _buildParagraph(
              'The Service Provider does not use user-generated content to train external AI models unless specifically disclosed and permitted by applicable law.',
            ),

            _buildSection('How We Use Your Information'),
            _buildParagraph('The Service Provider may use information collected to:'),
            _buildBulletPoint('Create and manage user accounts'),
            _buildBulletPoint('Provide Application functionality'),
            _buildBulletPoint('Enable collaboration and networking features'),
            _buildBulletPoint('Deliver AI-powered services'),
            _buildBulletPoint('Improve Application performance and user experience'),
            _buildBulletPoint('Analyze usage trends and Application effectiveness'),
            _buildBulletPoint('Detect fraud, abuse, and security incidents'),
            _buildBulletPoint('Respond to support requests'),
            _buildBulletPoint('Send important notices, updates, and service-related communications'),
            _buildBulletPoint('Comply with legal obligations'),

            _buildSection('User Content'),
            _buildParagraph(
              'The Application allows users to create profiles, share skills, participate in discussions, collaborate on projects, exchange messages, and interact with AI-powered features.',
            ),
            _buildParagraph(
              'Any content submitted by users remains their responsibility. The Service Provider may store, process, and display such content as necessary to operate, maintain, and improve the Application.',
            ),

            _buildSection('Location Information'),
            _buildParagraph('The Application may collect location information when you grant permission.'),
            _buildParagraph('Location information may be used to:'),
            _buildBulletPoint('Provide location-based features'),
            _buildBulletPoint('Improve Application functionality'),
            _buildBulletPoint('Enhance user experience'),
            _buildBulletPoint('Support analytics and service improvements'),
            _buildParagraph('You may disable location access through your device settings at any time.'),

            _buildSection('Cookies and Similar Technologies'),
            _buildParagraph(
              'The Application and its third-party service providers may use cookies, software development kits (SDKs), analytics tools, and similar technologies to:',
            ),
            _buildBulletPoint('Maintain Application functionality'),
            _buildBulletPoint('Analyze usage and performance'),
            _buildBulletPoint('Improve services'),
            _buildBulletPoint('Provide security features'),
            _buildParagraph('Where required by applicable law, consent will be obtained before using non-essential technologies.'),

            _buildSection('Third-Party Services'),
            _buildParagraph('The Application may use third-party service providers to support:'),
            _buildBulletPoint('Cloud hosting'),
            _buildBulletPoint('Analytics'),
            _buildBulletPoint('Authentication'),
            _buildBulletPoint('AI services'),
            _buildBulletPoint('Notification delivery'),
            _buildBulletPoint('Performance monitoring'),
            _buildParagraph(
              'These providers may process information on behalf of the Service Provider only as necessary to perform their services.',
            ),

            _buildSection('Sharing of Information'),
            _buildParagraph('The Service Provider may share information:'),
            _buildBulletPoint('With trusted service providers who assist in operating the Application'),
            _buildBulletPoint('To comply with legal obligations'),
            _buildBulletPoint('To protect the rights, safety, or security of users or others'),
            _buildBulletPoint('To investigate fraud, abuse, or security incidents'),
            _buildBulletPoint('In connection with a merger, acquisition, financing, or sale of assets'),
            _buildBulletPoint('With your consent'),
            _buildParagraph('The Service Provider does not sell users\' personal information.'),

            _buildSection('Data Storage and Processing'),
            _buildParagraph(
              'Your information may be stored and processed on servers located in Pakistan or in other countries where the Service Provider or its technology providers operate.',
            ),
            _buildParagraph(
              'By using the Application, you acknowledge that your information may be transferred to and processed in jurisdictions with data protection laws that may differ from those in your country of residence.',
            ),
            _buildParagraph('Reasonable measures will be taken to protect your information regardless of where it is processed.'),

            _buildSection('Data Retention'),
            _buildParagraph('The Service Provider retains information for as long as necessary to:'),
            _buildBulletPoint('Provide the Application and related services'),
            _buildBulletPoint('Fulfill legal obligations'),
            _buildBulletPoint('Resolve disputes'),
            _buildBulletPoint('Enforce agreements'),
            _buildBulletPoint('Maintain security and prevent fraud'),
            _buildSubSection('Generally:'),
            _buildBulletPoint('Account information is retained while your account remains active.'),
            _buildBulletPoint('User-generated content may remain available until deleted by you or removed by the Service Provider.'),
            _buildBulletPoint('Certain information may be retained for legal, security, or operational purposes even after account deletion.'),

            _buildSection('Account Deletion'),
            _buildParagraph(
              'Users may request deletion of their account and associated personal information by contacting the Service Provider.',
            ),
            _buildParagraph(
              'Upon receiving a verified request, personal information will be deleted or anonymized within a reasonable period unless retention is required by law, security requirements, fraud prevention purposes, or legitimate operational needs.',
            ),

            _buildSection('Your Rights'),
            _buildParagraph('Depending on your location and applicable laws, you may have the right to:'),
            _buildBulletPoint('Access your personal information'),
            _buildBulletPoint('Correct inaccurate information'),
            _buildBulletPoint('Request deletion of personal information'),
            _buildBulletPoint('Withdraw consent where processing is based on consent'),
            _buildBulletPoint('Object to certain processing activities'),
            _buildParagraph('To exercise your rights, contact the Service Provider using the contact details below.'),

            _buildSection('Children\'s Privacy'),
            _buildParagraph('The Application is intended for users who are at least 16 years of age.'),
            _buildParagraph(
              'The Service Provider does not knowingly collect personal information from children under 16. If the Service Provider becomes aware that such information has been collected, reasonable steps will be taken to delete it.',
            ),
            _buildParagraph('Parents or guardians who believe a child has provided personal information should contact the Service Provider.'),

            _buildSection('Security'),
            _buildParagraph(
              'The Service Provider takes reasonable administrative, technical, and organizational measures to protect personal information against unauthorized access, disclosure, alteration, or destruction.',
            ),
            _buildParagraph(
              'However, no method of electronic transmission or storage is completely secure, and absolute security cannot be guaranteed.',
            ),

            _buildSection('Data Breach Notification'),
            _buildParagraph(
              'If a data breach affecting personal information occurs, the Service Provider will take appropriate steps to investigate and address the incident and will provide notifications where required by applicable law.',
            ),

            _buildSection('Changes to This Privacy Policy'),
            _buildParagraph('The Service Provider may update this Privacy Policy from time to time.'),
            _buildParagraph(
              'Updated versions will be posted within the Application with a revised effective date. Continued use of the Application after changes become effective constitutes acceptance of the updated Privacy Policy.',
            ),

            _buildSection('Contact Us'),
            _buildParagraph('If you have questions about this Privacy Policy or the handling of your information, please contact:'),
            Text(
              'Abdul Samad',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Email: abdulsamad7239@gmail.com',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            _buildParagraph(
              'By using the Application, you acknowledge that you have read and understood this Privacy Policy.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          fontSize: 18,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.bodyLarge.copyWith(
          height: 1.5,
          color: AppColors.textPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.5,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
