import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/availability_model.dart';

class TimeOffForm extends ConsumerStatefulWidget {
  final TimeOffRecord? initialRecord;
  final String businessId;
  final Future<void> Function(TimeOffRecord record) onSubmit;
  final bool isLoading;

  const TimeOffForm({
    super.key,
    this.initialRecord,
    required this.businessId,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  ConsumerState<TimeOffForm> createState() => _TimeOffFormState();
}

class _TimeOffFormState extends ConsumerState<TimeOffForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _startDate;
  late DateTime _endDate;
  final bool _isFullDay = true;
  String? _selectedStaffId; // null = entire business

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    _titleController = TextEditingController(text: rec?.title ?? '');
    _noteController = TextEditingController(text: rec?.note ?? '');
    _startDate = rec?.startDate ?? DateTime.now();
    _endDate = rec?.endDate ?? DateTime.now();
    _selectedStaffId = rec?.staffId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be earlier than start date.'),
        ),
      );
      return;
    }

    final record = TimeOffRecord(
      id:
          widget.initialRecord?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      businessId: widget.businessId,
      staffId: _selectedStaffId,
      title: _titleController.text.trim(),
      startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      endDate: DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      ),
      isFullDay: _isFullDay,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.initialRecord?.createdAt ?? DateTime.now(),
    );

    await widget.onSubmit(record);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final staffListAsync = ref.watch(staffProvider);
    final staffList = staffListAsync.value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          AppTextField(
            label: 'Holiday / Time Off Reason',
            isRequired: true,
            hint: 'e.g. Diwali Holiday, Staff Training, Renovation',
            controller: _titleController,
            prefixIcon: const Icon(Icons.event_busy_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please provide a title or reason';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Assignment Dropdown: All Business vs Specific Staff
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Applies To',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedStaffId,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Entire Business (All Staff & Services)'),
                  ),
                  ...staffList.map((st) {
                    return DropdownMenuItem<String?>(
                      value: st.id,
                      child: Text('Specific Staff: ${st.name}'),
                    );
                  }),
                ],
                onChanged: (val) => setState(() => _selectedStaffId = val),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDate(isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkInputFill
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(_startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 16),
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
                    Text(
                      'End Date *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickDate(isStart: false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkInputFill
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(_endDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Note (Optional)
          AppTextField(
            label: 'Notes / Remarks (Optional)',
            isRequired: false,
            hint: 'Additional details or instructions',
            controller: _noteController,
            keyboardType: TextInputType.multiline,
            prefixIcon: const Icon(Icons.notes_outlined),
          ),
          const SizedBox(height: 24),

          // Submit
          AppButton(
            label: widget.initialRecord != null
                ? 'Update Time Off'
                : 'Save Time Off',
            onPressed: _handleSubmit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
