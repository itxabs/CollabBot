import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/social_media_view_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'add_social_media_screen.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialMediaViewModel>().loadSocialLinks();
    });
  }

  Widget _getPlatformIcon(String platform, {double size = 24, Color color = AppColors.primary}) {
    switch (platform.toLowerCase()) {
      case 'linkedin': return FaIcon(FontAwesomeIcons.linkedin, size: size, color: color);
      case 'github': return FaIcon(FontAwesomeIcons.github, size: size, color: color);
      case 'facebook': return FaIcon(FontAwesomeIcons.facebook, size: size, color: color);
      case 'twitter': return FaIcon(FontAwesomeIcons.xTwitter, size: size, color: color);
      case 'instagram': return FaIcon(FontAwesomeIcons.instagram, size: size, color: color);
      case 'website': return Icon(Icons.language, size: size, color: color);
      default: return Icon(Icons.link, size: size, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SocialMediaViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Social Media', style: AppTextStyles.h3),
        centerTitle: true,
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
                MaterialPageRoute(builder: (_) => const AddSocialMediaScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isLoading && viewModel.socialLinks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: viewModel.loadSocialLinks,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Social Links', style: AppTextStyles.h3.copyWith(fontSize: 18)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: viewModel.socialLinks.isEmpty
                          ? const Center(child: Text('No social profiles added', style: TextStyle(color: AppColors.textSecondary)))
                          : ListView.separated(
                              itemCount: viewModel.socialLinks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final link = viewModel.socialLinks[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      _getPlatformIcon(link.platform),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              link.platform.toUpperCase(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            Text(
                                              link.url,
                                              style: AppTextStyles.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                        onPressed: () => viewModel.deleteSocialLink(link.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

