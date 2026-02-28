import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/events_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../data/models/event_model.dart';
import '../../widgets/events/event_card.dart';

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
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userRole = authViewModel.currentUser?.role.toLowerCase() ?? 'junior';
    final canCreate = userRole == 'senior' || userRole == 'alumni' || userRole == 'scnior' || userRole == 'almunai';


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Events', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(context, viewModel, authViewModel),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                : viewModel.upcomingEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No events found', style: AppTextStyles.bodyLarge),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.upcomingEvents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = viewModel.upcomingEvents[index];
                          return EventCard(
                            tag: event.category,
                            tagColor: _getCategoryColor(event.category),
                            title: event.title,
                            description: event.description,
                            date: DateFormat('MMM d, yyyy').format(event.date),
                            time: '${event.startTime} - ${event.endTime}',
                            location: event.venue,
                            attendees: '0/50 attending', // Placeholder for now
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workshop': return Colors.blue;
      case 'seminar': return Colors.orange;
      case 'career': return Colors.green;
      default: return AppColors.primary;
    }
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

  void _showCreateEventDialog(BuildContext context, EventsViewModel viewModel, AuthViewModel authViewModel) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final venueController = TextEditingController();
    final categoryController = TextEditingController(text: 'Workshop');
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Create New Event', style: AppTextStyles.h3),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Event Title'),
                TextField(controller: titleController, decoration: _inputDecoration('Enter title')),
                const SizedBox(height: 12),
                _buildFieldLabel('Category'),
                DropdownButtonFormField<String>(
                  value: categoryController.text,
                  items: ['Workshop', 'Seminar', 'Career', 'Social'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => categoryController.text = val!),
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Venue'),
                TextField(controller: venueController, decoration: _inputDecoration('Enter venue')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Date'),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _boxDecoration(),
                              child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Start Time'),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: startTime);
                              if (picked != null) setState(() => startTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _boxDecoration(),
                              child: Text(startTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Description'),
                TextField(controller: descController, maxLines: 3, decoration: _inputDecoration('Enter description')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || venueController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                      return;
                    }
                    final event = EventModel(
                      title: titleController.text,
                      category: categoryController.text,
                      description: descController.text,
                      venue: venueController.text,
                      date: selectedDate,
                      startTime: startTime.format(context),
                      endTime: endTime.format(context),
                      creatorId: authViewModel.currentUser?.userId ?? '',
                      creatorName: authViewModel.currentUser?.name,
                    );
                    final success = await viewModel.createEvent(event);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully!')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Post Event'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

