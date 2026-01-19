import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/events_view_model.dart';
import '../../core/constants/routes.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventsViewModel(),
      child: const _EventsContent(),
    );
  }
}

class _EventsContent extends StatelessWidget {
  const _EventsContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EventsViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Events', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, 
      ),
      body: Column(
        children: [
          // Custom Tab Bar Placeholder
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildTab('Upcoming', true),
                const SizedBox(width: 16),
                _buildTab('Saved', false),
                const SizedBox(width: 16),
                _buildTab('My Events', false),
              ],
            ),
          ),
          
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: viewModel.upcomingEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final event = viewModel.upcomingEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Column(
      children: [
        Text(
          text,
          style: isSelected
              ? AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)
              : AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 20,
            color: AppColors.primary,
          )
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.event_available, size: 48, color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.date,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.bookmark_border, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.title, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(event.location, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
