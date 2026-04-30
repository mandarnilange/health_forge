import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_example/widgets/record_list_item.dart';
import 'package:intl/intl.dart';

class DataBrowserScreen extends StatefulWidget {
  const DataBrowserScreen({required this.client, super.key});

  final HealthForgeClient client;

  @override
  State<DataBrowserScreen> createState() => _DataBrowserScreenState();
}

class _DataBrowserScreenState extends State<DataBrowserScreen> {
  MetricType _selectedMetric = MetricType.heartRate;
  late DateTimeRange _dateRange;
  List<HealthRecordMixin> _records = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    // Extend end to end-of-day so same-day picks return data.
    final endOfDay = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
    ).add(const Duration(days: 1));
    final range = TimeRange(
      start: _dateRange.start,
      end: endOfDay,
    );

    // Sync from all providers that support this metric in parallel.
    await Future.wait([
      for (final provider in widget.client.registry.supporting(_selectedMetric))
        widget.client.sync(
          provider: provider.providerType,
          metric: _selectedMetric,
          range: range,
        ),
    ]);

    // Read merged data from cache
    final records = await widget.client.cache.get(
      metric: _selectedMetric,
      range: range,
    );

    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  void _showRecordDetail(BuildContext context, HealthRecordMixin record) {
    final json = (record as dynamic).toJson() as Map<String, dynamic>;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final theme = Theme.of(context);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.providerRecordType,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        Chip(
                          label: Text(record.provider.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${dateFormat.format(record.startTime)}'
                      ' - ${dateFormat.format(record.endTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: json.entries.map((entry) {
                        final value = _formatJsonValue(entry.value);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  entry.key,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  value,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatJsonValue(dynamic value) {
    if (value == null) return '--';
    if (value is List) {
      if (value.isEmpty) return '[]';
      return value.map(_formatJsonValue).join('\n');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${_formatJsonValue(e.value)}')
          .join('\n');
    }
    return value.toString();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Data')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<MetricType>(
                  // Using value since initialValue is not yet stable.
                  // ignore: deprecated_member_use
                  value: _selectedMetric,
                  decoration: const InputDecoration(
                    labelText: 'Metric Type',
                    border: OutlineInputBorder(),
                  ),
                  items: MetricType.values.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMetric = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${_dateRange.start.month}/${_dateRange.start.day}'
                    ' - '
                    '${_dateRange.end.month}/${_dateRange.end.day}',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _fetch,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Fetch'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_records.length} records',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _records.isEmpty
                ? Center(
                    child: Text(
                      _loading ? '' : 'No records found. Tap Fetch to load.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return RecordListItem(
                        record: record,
                        onTap: () => _showRecordDetail(context, record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
