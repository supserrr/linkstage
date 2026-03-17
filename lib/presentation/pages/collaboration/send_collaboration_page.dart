import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_borders.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/collaboration_repository.dart';

const List<String> _standardEventTypes = [
  'Wedding',
  'Music',
  'Corporate',
  'Party',
  'Conference',
  'Concert',
  'Workshop',
];

/// Page for sending a collaboration proposal to a creative.
class SendCollaborationPage extends StatefulWidget {
  const SendCollaborationPage({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  State<SendCollaborationPage> createState() => _SendCollaborationPageState();
}

class _SendCollaborationPageState extends State<SendCollaborationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isSubmitting = false;
  String? _eventType;
  DateTime? _date;
  String _startTime = '';
  String _endTime = '';

  bool get _isPlanner =>
      sl<AuthRedirectNotifier>().user?.role == UserRole.eventPlanner;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    s = s.trim();
    final parts = s.split(RegExp(r'[:\s]')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }

  String _timeToStorage(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForDisplay(String stored) {
    if (stored.isEmpty) return 'Select time';
    final t = _parseTime(stored);
    if (t == null) return stored;
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final budgetVal = double.tryParse(_budgetController.text.trim());
    final locationVal = _locationController.text.trim().isEmpty
        ? null
        : _locationController.text.trim();
    final eventTypeVal = (_eventType != null &&
            _eventType!.isNotEmpty &&
            _eventType != 'Other')
        ? _eventType
        : null;
    final startTimeVal =
        _startTime.isNotEmpty ? _startTime : null;
    final endTimeVal = _endTime.isNotEmpty ? _endTime : null;

    try {
      final collaboration = await sl<CollaborationRepository>().createCollaboration(
        requesterId: user.id,
        targetUserId: widget.targetUserId,
        description: _descriptionController.text.trim(),
        title: _titleController.text.trim(),
        budget: budgetVal,
        date: _date,
        startTime: startTimeVal,
        endTime: endTimeVal,
        location: locationVal,
        eventType: eventTypeVal,
      );
      final requesterName =
          user.displayName ?? user.username ?? user.email;
      sl<PushNotificationService>().notifyUser(
        targetUserId: widget.targetUserId,
        title: 'New collaboration proposal',
        body: '$requesterName sent you a proposal',
        data: {
          'route': '/collaboration/detail',
          'collaborationId': collaboration.id,
          'type': 'collaboration_new',
        },
      );
      if (!mounted) return;
      showToast(context, 'Proposal sent');
      context.go(AppRoutes.messages);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showToast(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Collaboration Proposal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Project or event name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'e.g. Wedding Photography, Corporate Event DJ',
                  border: OutlineInputBorder(),
                  helperText: 'Required for direct proposals',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please enter a project or event name';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Your message',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText:
                      'Tell the creative what kind of collaboration or project you have in mind...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText: 'Required',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please describe what you want';
                  return null;
                },
              ),
              if (_isPlanner) ...[
                const SizedBox(height: 24),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 24),
                Text(
                  'Event details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional — help the creative understand your project',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: AppBorders.borderRadius,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _eventType ?? 'Other',
                        decoration: const InputDecoration(
                          labelText: 'Event type',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          ..._standardEventTypes.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _eventType = v),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final initial = _date ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        borderRadius: AppBorders.borderRadius,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            hintText: 'Select event date',
                          ),
                          child: Text(
                            _date != null
                                ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _date != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final initial = _parseTime(_startTime) ??
                                const TimeOfDay(hour: 9, minute: 0);
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: initial,
                                );
                                if (picked != null) {
                                  setState(
                                    () => _startTime = _timeToStorage(picked),
                                  );
                                }
                              },
                              borderRadius: AppBorders.borderRadius,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _formatTimeForDisplay(_startTime),
                                  style: TextStyle(
                                    color: _startTime.isNotEmpty
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final initial = _parseTime(_endTime) ??
                                    const TimeOfDay(hour: 17, minute: 0);
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: initial,
                                );
                                if (picked != null) {
                                  setState(
                                    () => _endTime = _timeToStorage(picked),
                                  );
                                }
                              },
                              borderRadius: AppBorders.borderRadius,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _formatTimeForDisplay(_endTime),
                                  style: TextStyle(
                                    color: _endTime.isNotEmpty
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Budget',
                          hintText: 'Optional, in RWF',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: LoadingAnimationWidget.stretchedDots(
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      )
                    : const Text('Send Proposal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
