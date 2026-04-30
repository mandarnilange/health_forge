import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_sleep_response.dart';

/// Maps Oura API sleep data to [SleepSession] models.
class SleepMapper {
  const SleepMapper._();

  /// Converts sleep response data to [SleepSession] records with hypnogram.
  static List<SleepSession> map(OuraSleepResponse response) {
    return response.data.map(_mapOne).toList();
  }

  static SleepSession _mapOne(OuraSleepData data) {
    final start = DateTime.parse(data.bedtimeStart);
    final end = DateTime.parse(data.bedtimeEnd);

    return SleepSession(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'sleep',
      providerRecordId: data.id,
      startTime: start,
      endTime: end,
      capturedAt: DateTime.now(),
      totalSleepMinutes: data.totalSleepDuration != null
          ? data.totalSleepDuration! ~/ 60
          : null,
      remMinutes:
          data.remSleepDuration != null ? data.remSleepDuration! ~/ 60 : null,
      deepMinutes:
          data.deepSleepDuration != null ? data.deepSleepDuration! ~/ 60 : null,
      lightMinutes: data.lightSleepDuration != null
          ? data.lightSleepDuration! ~/ 60
          : null,
      efficiency: data.efficiency,
      stages: _parseHypnogram(data.sleepPhase5Min, start),
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }

  static List<SleepStageSegment> _parseHypnogram(
    String? hypnogram,
    DateTime bedtimeStart,
  ) {
    if (hypnogram == null || hypnogram.isEmpty) return const [];

    return List.generate(hypnogram.length, (i) {
      final stageStart = bedtimeStart.add(Duration(minutes: i * 5));
      final stageEnd = stageStart.add(const Duration(minutes: 5));
      final digit = int.parse(hypnogram[i]);

      return SleepStageSegment(
        stage: _digitToStage(digit),
        startTime: stageStart,
        endTime: stageEnd,
      );
    });
  }

  static SleepStage _digitToStage(int digit) {
    return switch (digit) {
      1 => SleepStage.deep,
      2 => SleepStage.light,
      3 => SleepStage.rem,
      4 => SleepStage.awake,
      _ => SleepStage.unknown,
    };
  }
}
