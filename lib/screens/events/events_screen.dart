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
    
    final String userRole = authViewModel.currentUser?.role.trim().toLowerCase() ?? 'not_loaded';
    
    final bool canCreate = userRole != 'junior' && 
                          userRole != 'not_loaded' &&
                          (userRole == 'senior' || 
                           userRole == 'alumni' || 
                           userRole == 'scnior' || 
                           userRole == 'scior' || 
                           userRole == 'sciomnri' || 
                           userRole == 'almunai' || 
                           userRole == 'almunaii');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events Hub', style: AppTextStyles.h2),
            Text('Signed in as: ${authViewModel.currentUser?.name ?? "User"}', 
                 style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
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
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: viewModel.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search for workshops, seminars...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(context, 'Upcoming', viewModel.currentTab == 'Upcoming', viewModel),
                  const SizedBox(width: 8),
                  _buildTab(context, 'Saved', viewModel.currentTab == 'Saved', viewModel),
                  const SizedBox(width: 8),
                  _buildTab(context, 'My Events', viewModel.currentTab == 'My Events', viewModel),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No events found', style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey)),
                            if (viewModel.currentTab == 'Upcoming')
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Check back later for newly approved events!', 
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListAnimation(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.filteredEvents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final event = viewModel.filteredEvents[index];
                          final isMyEvent = event.creatorId == authViewModel.currentUser?.userId;
                          
                          return EventCard(
                            tag: event.category,
                            tagColor: _getCategoryColor(event.category),
                            title: event.title,
                            description: event.description,
                            date: DateFormat('EEE, MMM d, yyyy').format(event.date),
                            time: '${event.startTime.substring(0, 5)} - ${event.endTime.substring(0, 5)}',
                            location: event.venue,
                            imageUrl: event.imageUrl,
                            attendees: '${event.enrolledCount} / ${event.totalSeats} spots',
                            isSaved: false, // In a real app, check if saved
                            onSave: () => viewModel.toggleSaveEvent(event),
                            onRegister: () async {
                              // 1. Check if Full
                              if (event.totalSeats > 0 && event.enrolledCount >= event.totalSeats) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registration closed: Full capacity'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              // 2. Check if Date passed
                              final now = DateTime.now();
                              final eventDate = DateTime(event.date.year, event.date.month, event.date.day, 23, 59);
                              if (eventDate.isBefore(now)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registration closed: Event has passed'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              final result = await viewModel.registerForEvent(event);
                              if (context.mounted) {
                                if (result == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Successfully registered!'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workshop': return const Color(0xFF3B82F6);
      case 'seminar': return const Color(0xFFF59E0B);
      case 'career': return const Color(0xFF10B981);
      case 'social': return const Color(0xFFEC4899);
      default: return AppColors.primary;
    }
  }

  Widget _buildTab(BuildContext context, String text, bool isSelected, EventsViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.setTab(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context, EventsViewModel viewModel, AuthViewModel authViewModel) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final venueController = TextEditingController();
    final seatsController = TextEditingController(text: '50');
    final imageController = TextEditingController();
    final categoryController = TextEditingController(text: 'Workshop');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Post New Event', style: AppTextStyles.h3),
                const SizedBox(height: 24),
                
                _buildFieldLabel('Event Title'),
                TextField(controller: titleController, decoration: _inputDecoration('e.g. Flutter Workshop')),
                const SizedBox(height: 16),
                
                _buildFieldLabel('Category'),
                DropdownButtonFormField<String>(
                  value: categoryController.text,
                  items: ['Workshop', 'Seminar', 'Career', 'Social'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => categoryController.text = val!),
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: 16),
                
                _buildFieldLabel('Venue'),
                TextField(controller: venueController, decoration: _inputDecoration('e.g. Auditorium A')),
                const SizedBox(height: 16),

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
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                                ],
                              ),
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
                          _buildFieldLabel('Seats Available'),
                          TextField(
                            controller: seatsController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Max capacity'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Banner Image URL (Optional)'),
                TextField(controller: imageController, decoration: _inputDecoration('https://example.com/image.jpg')),
                const SizedBox(height: 16),
                
                _buildFieldLabel('Description'),
                TextField(controller: descController, maxLines: 3, decoration: _inputDecoration('Describe your event...')),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || venueController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                      return;
                    }
                    
                    String formatTime(TimeOfDay time) {
                      final h = time.hour.toString().padLeft(2, '0');
                      final m = time.minute.toString().padLeft(2, '0');
                      return '$h:$m:00';
                    }

                    final event = EventModel(
                      title: titleController.text,
                      category: categoryController.text,
                      description: descController.text,
                      venue: venueController.text,
                      date: selectedDate,
                      startTime: formatTime(startTime),
                      endTime: formatTime(endTime),
                      creatorId: authViewModel.currentUser?.userId ?? '',
                      creatorName: authViewModel.currentUser?.name,
                      totalSeats: int.tryParse(seatsController.text) ?? 50,
                      imageUrl: imageController.text,
                      status: '1', // 1 = Pending
                    );

                    final result = await viewModel.createEvent(event);
                    if (context.mounted) {
                      if (result == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Your post will be published after admin approval!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: viewModel.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit for Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey[50],
      border: Border.all(color: Colors.grey[200]!),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class ListAnimation extends StatelessWidget {
  final Widget child;
  const ListAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

