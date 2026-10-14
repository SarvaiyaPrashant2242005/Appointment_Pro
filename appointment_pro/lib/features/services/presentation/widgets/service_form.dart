import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/service_model.dart';

class ServiceForm extends StatefulWidget {
  final ServiceModel? initialService;
  final String businessId;
  final Future<void> Function(ServiceModel service) onSubmit;
  final bool isLoading;

  const ServiceForm({
    super.key,
    this.initialService,
    required this.businessId,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _bufferController;
  late bool _isActive;

  static const List<int> _suggestedDurations = [15, 30, 45, 60, 90, 120];
  static const List<int> _suggestedBuffers = [0, 5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    final s = widget.initialService;
    _nameController = TextEditingController(text: s?.name ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _priceController = TextEditingController(
      text: s != null
          ? (s.price == s.price.roundToDouble()
                ? s.price.toInt().toString()
                : s.price.toString())
          : '',
    );
    _durationController = TextEditingController(
      text: s != null ? s.durationMinutes.toString() : '30',
    );
    _bufferController = TextEditingController(
      text: s != null ? s.bufferMinutes.toString() : '0',
    );
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final duration = int.parse(_durationController.text.trim());
    final buffer = int.parse(_bufferController.text.trim());

    final now = DateTime.now();
    final service = ServiceModel(
      id:
          widget.initialService?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      businessId: widget.businessId,
      name: name,
      description: description.isEmpty ? null : description,
      price: price,
      durationMinutes: duration,
      bufferMinutes: buffer,
      isActive: _isActive,
      createdAt: widget.initialService?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.onSubmit(service);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentDuration = int.tryParse(_durationController.text) ?? -1;
    final currentBuffer = int.tryParse(_bufferController.text) ?? -1;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Name
          AppTextField(
            label: 'Service Name',
            isRequired: true,
            hint: 'e.g. Haircut & Styling, Dental Checkup',
            controller: _nameController,
            prefixIcon: const Icon(Icons.spa_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Service name is required';
              }
              if (v.trim().length < 2) {
                return 'Service name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Price
          AppTextField(
            label: 'Price (₹)',
            isRequired: true,
            hint: '0.00',
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Price is required';
              }
              final price = double.tryParse(v.trim());
              if (price == null) {
                return 'Enter a valid price';
              }
              if (price < 0) {
                return 'Price cannot be negative';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Duration Minutes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Duration (Minutes)',
                isRequired: true,
                hint: 'e.g. 30',
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: const Icon(Icons.schedule_rounded),
                onFieldSubmitted: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Duration is required';
                  }
                  final dur = int.tryParse(v.trim());
                  if (dur == null || dur <= 0) {
                    return 'Duration must be greater than 0 minutes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Duration Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestedDurations.map((dur) {
                  final isSelected = currentDuration == dur;
                  return ChoiceChip(
                    label: Text('${dur}m'),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accent
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _durationController.text = dur.toString();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Buffer Time Minutes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Buffer Time (Minutes)',
                isRequired: false,
                hint: '0',
                controller: _bufferController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: const Icon(Icons.hourglass_bottom_rounded),
                onFieldSubmitted: (_) => setState(() {}),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    final buf = int.tryParse(v.trim());
                    if (buf == null || buf < 0) {
                      return 'Buffer time cannot be negative';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Buffer Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestedBuffers.map((buf) {
                  final isSelected = currentBuffer == buf;
                  return ChoiceChip(
                    label: Text(buf == 0 ? 'None' : '${buf}m'),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accent
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _bufferController.text = buf.toString();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description (Optional)
          AppTextField(
            label: 'Description',
            isRequired: false,
            hint: 'Describe what is included in this service (Optional)',
            controller: _descriptionController,
            keyboardType: TextInputType.multiline,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
          const SizedBox(height: 16),

          // Active/Inactive Card
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Available for Booking',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isActive
                          ? 'Clients can book this service'
                          : 'Temporarily hidden from booking',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColors.accent,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          AppButton(
            label: widget.initialService != null
                ? 'Update Service'
                : 'Save Service',
            onPressed: _handleSubmit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
