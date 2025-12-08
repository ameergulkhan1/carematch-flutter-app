import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/booking_model.dart';
import '../../../../models/care_session_model.dart';
import '../../../../services/session_service.dart';
import '../../../../core/constants/app_colors.dart';

class SessionExecutionScreen extends StatefulWidget {
  final BookingModel booking;

  const SessionExecutionScreen({
    super.key,
    required this.booking,
  });

  @override
  State<SessionExecutionScreen> createState() => _SessionExecutionScreenState();
}

class _SessionExecutionScreenState extends State<SessionExecutionScreen> {
  final SessionService _sessionService = SessionService();
  final TextEditingController _notesController = TextEditingController();

  CareSession? _currentSession;
  bool _isLoading = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  final List<String> _tasks = [
    'Personal hygiene assistance',
    'Medication administration',
    'Meal preparation',
    'Light housekeeping',
    'Companionship',
    'Mobility assistance',
  ];
  final Set<String> _completedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final sessions =
          await _sessionService.getCaregiverSessions(user.uid).first;
      final activeSession = sessions
          .where((s) =>
              s.bookingId == widget.booking.id &&
              s.status == SessionStatus.inProgress)
          .firstOrNull;

      if (activeSession != null) {
        setState(() {
          _currentSession = activeSession;
          if (activeSession.actualStartTime != null) {
            _elapsed =
                DateTime.now().difference(activeSession.actualStartTime!);
            _startTimer();
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession?.actualStartTime != null) {
        setState(() {
          _elapsed =
              DateTime.now().difference(_currentSession!.actualStartTime!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool sessionActive =
        _currentSession?.status == SessionStatus.inProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Execution'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            widget.booking.clientName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.clientName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.booking.serviceType.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.booking.startDate.day}/${widget.booking.startDate.month}/${widget.booking.startDate.year}',
                        ),
                        const SizedBox(width: 24),
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.booking.startTime} - ${widget.booking.endTime}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (sessionActive) ...[
              const SizedBox(height: 24),

              // Timer Card
              Card(
                elevation: 2,
                color: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Session Duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tasks Checklist
              const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _tasks.map((task) {
                    final isCompleted = _completedTasks.contains(task);
                    return CheckboxListTile(
                      title: Text(
                        task,
                        style: TextStyle(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: isCompleted,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _completedTasks.add(task);
                            _logTaskCompletion(task);
                          } else {
                            _completedTasks.remove(task);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Session Notes
              const Text(
                'Session Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add notes about the session...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Photo Upload Section
              const Text(
                'Session Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement photo upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 32),

              // End Session Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _endSession,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('End Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),

              // Start Session Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Start Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final sessionId = await _sessionService.startSession(
        bookingId: widget.booking.id,
        caregiverId: user.uid,
        caregiverName: user.displayName ?? 'Caregiver',
        clientId: widget.booking.clientId,
        clientName: widget.booking.clientName,
        scheduledDate: widget.booking.startDate,
        scheduledStartTime: widget.booking.startTime ?? '09:00',
        scheduledEndTime: widget.booking.endTime ?? '17:00',
        tasks: _tasks,
      );

      if (sessionId != null) {
        await _loadActiveSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Session started'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      if (_currentSession == null) throw Exception('No active session');

      // Add notes if any
      if (_notesController.text.trim().isNotEmpty) {
        await _sessionService.addSessionNotes(
          _currentSession!.id,
          _notesController.text.trim(),
        );
      }

      // Complete session
      final success =
          await _sessionService.completeSession(_currentSession!.id);

      if (success && mounted) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Session completed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logTaskCompletion(String task) async {
    if (_currentSession != null) {
      await _sessionService.logTaskCompletion(
        _currentSession!.id,
        task,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }
}
