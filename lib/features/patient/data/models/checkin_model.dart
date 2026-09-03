import 'package:flutter/material.dart';

/// Models for the wellbeing check-in feature, mapping the Go API's
/// `/checkins` and `/sleep` responses.
///
/// The rating scales are configuration, not code: Business Central decides
/// which scales exist, what range each covers, how its bands are labelled and
/// coloured, and which direction counts as good. Adding "Pain" in BC must make
/// a pain slider appear here without a release, so nothing in this file may
/// hardcode a scale name.

/// Which end of a scale is the good outcome. Mood improves as it rises;
/// anxiety and pain worsen.
enum RatingDirection {
  higherIsBetter,
  higherIsWorse;

  static RatingDirection fromJson(String? value) =>
      value == 'higherIsWorse' ? higherIsWorse : higherIsBetter;
}

/// A labelled stretch of a scale — 7–8 might be "High".
class RatingBand {
  final int tier;
  final int lowerLimit;
  final int upperLimit;
  final String caption;

  /// Hex colour chosen in BC, or null to let the app pick.
  final Color? colour;

  const RatingBand({
    required this.tier,
    required this.lowerLimit,
    required this.upperLimit,
    required this.caption,
    this.colour,
  });

  bool contains(int value) => value >= lowerLimit && value <= upperLimit;

  factory RatingBand.fromJson(Map<String, dynamic> json) {
    return RatingBand(
      tier: json['tier'] as int? ?? 0,
      lowerLimit: json['lowerLimit'] as int? ?? 0,
      upperLimit: json['upperLimit'] as int? ?? 0,
      caption: json['caption'] as String? ?? '',
      colour: _parseHexColour(json['colour'] as String?),
    );
  }

  /// Parses BC's `#RRGGBB`. Returns null rather than throwing on anything
  /// unexpected — a mistyped colour should cost a tint, not the whole screen.
  static Color? _parseHexColour(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

/// A scale the patient scores themselves against.
class RatingType {
  final String code;
  final String description;
  final String prompt;
  final int minValue;
  final int maxValue;
  final RatingDirection direction;
  final int sequence;
  final List<RatingBand> bands;

  const RatingType({
    required this.code,
    required this.description,
    required this.prompt,
    required this.minValue,
    required this.maxValue,
    required this.direction,
    required this.sequence,
    required this.bands,
  });

  /// Midpoint of the scale — a neutral starting position that doesn't nudge
  /// the patient toward either end.
  int get defaultValue => ((minValue + maxValue) / 2).round();

  /// The band [value] falls into, or null when the scale has no bands.
  RatingBand? bandFor(int value) {
    for (final band in bands) {
      if (band.contains(value)) return band;
    }
    return null;
  }

  factory RatingType.fromJson(Map<String, dynamic> json) {
    final rawBands = (json['bands'] as List<dynamic>? ?? const []);
    return RatingType(
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      minValue: json['minValue'] as int? ?? 0,
      maxValue: json['maxValue'] as int? ?? 10,
      direction: RatingDirection.fromJson(json['direction'] as String?),
      sequence: json['sequence'] as int? ?? 0,
      bands: rawBands
          .map((b) => RatingBand.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One score recorded during a check-in. [bandCaption] is the label that
/// applied when it was taken, so retuning a band later doesn't rewrite history.
class Rating {
  final String typeCode;
  final int value;
  final String bandCaption;

  const Rating({
    required this.typeCode,
    required this.value,
    required this.bandCaption,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      typeCode: json['typeCode'] as String? ?? '',
      value: json['value'] as int? ?? 0,
      bandCaption: json['bandCaption'] as String? ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'typeCode': typeCode,
    'value': value,
  };
}

/// One wellbeing entry with the scores taken at the same moment. Patients may
/// record as many per day as they like, and an entry may carry notes only.
class Checkin {
  final int entryNo;
  final DateTime? recordedAt;
  final String notes;
  final bool shareWithDoctor;
  final List<Rating> ratings;

  const Checkin({
    required this.entryNo,
    required this.recordedAt,
    required this.notes,
    required this.shareWithDoctor,
    required this.ratings,
  });

  /// The score for [typeCode], or null when this entry didn't record one.
  Rating? ratingFor(String typeCode) {
    for (final rating in ratings) {
      if (rating.typeCode == typeCode) return rating;
    }
    return null;
  }

  factory Checkin.fromJson(Map<String, dynamic> json) {
    final rawRatings = (json['ratings'] as List<dynamic>? ?? const []);
    return Checkin(
      entryNo: json['entryNo'] as int? ?? 0,
      recordedAt: _parseDateTime(
        json['date'] as String?,
        json['time'] as String?,
      ),
      notes: json['notes'] as String? ?? '',
      shareWithDoctor: json['shareWithDoctor'] as bool? ?? false,
      ratings: rawRatings
          .map((r) => Rating.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Combines BC's separate date and time columns. BC returns time with
  /// milliseconds (`22:50:48.707`), which [DateTime.parse] accepts.
  static DateTime? _parseDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final timePart = (time == null || time.isEmpty) ? '00:00:00' : time;
    return DateTime.tryParse('${date}T$timePart');
  }
}

/// One night's sleep. Keyed on date in BC, so re-saving a date replaces it.
class SleepLog {
  final DateTime? date;
  final double hours;
  final String notes;
  final bool shareWithDoctor;

  const SleepLog({
    required this.date,
    required this.hours,
    required this.notes,
    required this.shareWithDoctor,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      shareWithDoctor: json['shareWithDoctor'] as bool? ?? false,
    );
  }
}
