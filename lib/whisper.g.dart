// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whisper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Whisper _$WhisperFromJson(Map<String, dynamic> json) => Whisper(
      json['model'],
      Whisper._contextParamsFromJson(json['cparams'] as Uint8List),
      outputMode: json['outputMode'] as String? ?? "plaintext",
      initMode: json['initMode'] as String? ?? "late",
    )
      ..ctx = Whisper._ctxFromJson((json['ctx'] as num).toInt())
      ..nNew = (json['nNew'] as num).toInt()
      ..lastNSegments = (json['lastNSegments'] as num).toInt()
      ..timeOffset = (json['timeOffset'] as num).toInt()
      ..startTime = (json['startTime'] as num).toInt()
      ..endTime = (json['endTime'] as num).toInt();

Map<String, dynamic> _$WhisperToJson(Whisper instance) => <String, dynamic>{
      'ctx': Whisper._ctxToJson(instance.ctx),
      'nNew': instance.nNew,
      'outputMode': instance.outputMode,
      'lastNSegments': instance.lastNSegments,
      'timeOffset': instance.timeOffset,
      'model': instance.model,
      'cparams': Whisper._contextParamsToJson(instance.cparams),
      'initMode': instance.initMode,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
    };
