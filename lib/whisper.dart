import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:libmpv_dart/gen/bindings.dart';
import 'package:libmpv_dart/libmpv.dart' as mpv;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:whisper4dart/library.dart';
import 'package:whisper4dart/other.dart';
import 'whisper4dart_bindings_generated.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.

class Whisper {
  late Pointer<whisper_context> ctx;
  SendPort? _isolateSendPort;
  int get handle => ctx.address;
  ValueNotifier<String> result = ValueNotifier("");
  int nNew = 0;
  String outputMode;
  int lastNSegments = 0;
  Whisper(dynamic model, whisper_context_params cparams,
      {this.outputMode = "plaintext"}) {
    if (!WhisperLibrary.loaded) {
      if (!WhisperLibrary.flagFirst) {
        WhisperLibrary.init();
      } else {
        throw Exception('libwhisper is not loaded!');
      }
    }
    if (model is String) {
      ctx = WhisperLibrary.binding.whisper_init_from_file_with_params(
          model.toNativeUtf8().cast<Char>(), cparams);
    } else if (model is Uint8List) {
      var ptr = allocateUint8Pointer(model);
      ctx = WhisperLibrary.binding.whisper_init_from_buffer_with_params(
          ptr.cast(), model.length, cparams);
    } else {
      throw Exception("Invalid mode");
    }
  }
  Whisper.useCtx(Pointer<whisper_context> context,
      {this.outputMode = "plaintext"}) {
    if (!WhisperLibrary.loaded) {
      if (!WhisperLibrary.flagFirst) {
        WhisperLibrary.init();
      } else {
        throw Exception('libwhisper is not loaded!');
      }
    }
    ctx = context;
  }

  void full(whisper_full_params wparams, List<double> pcmf32List) {
    Pointer<Float> pcmf32 = allocateFloatPointer(pcmf32List);
    if (WhisperLibrary.binding
            .whisper_full(ctx, wparams, pcmf32, pcmf32List.length) !=
        0) {
      throw Exception("failed to process audio");
    }
  }

  void fullParallel(
      whisper_full_params wparams, List<double> pcmf32List, int nProcessors) {
    Pointer<Float> pcmf32 = allocateFloatPointer(pcmf32List);
    if (WhisperLibrary.binding.whisper_full_parallel(
            ctx, wparams, pcmf32, pcmf32List.length, nProcessors) !=
        0) {
      throw Exception("failed to process audio");
    }
  }

  int fullNSegments() {
    return WhisperLibrary.binding.whisper_full_n_segments(ctx);
  }

  String fullGetSegmentsText(int i) {
    return WhisperLibrary.binding
        .whisper_full_get_segment_text(ctx, i)
        .cast<Utf8>()
        .toDartString();
  }

  String printSystemInfo() {
    return WhisperLibrary.binding
        .whisper_print_system_info()
        .cast<Utf8>()
        .toDartString();
  }

  void free() {
    return WhisperLibrary.binding.whisper_free(ctx);
  }

  bool isMultilingual() {
    return WhisperLibrary.binding.whisper_is_multilingual(ctx) != 0;
  }

  int fullLangId() {
    return WhisperLibrary.binding.whisper_full_lang_id(ctx);
  }

  String langStr() {
    return WhisperLibrary.binding
        .whisper_lang_str(fullLangId())
        .cast<Utf8>()
        .toDartString();
  }

  int fullGetSegmentT0(int i) {
    return WhisperLibrary.binding.whisper_full_get_segment_t0(ctx, i);
  }

  int fullGetSegmentT1(int i) {
    return WhisperLibrary.binding.whisper_full_get_segment_t1(ctx, i);
  }

  Future<String> _infer(String inputPath, whisper_full_params wparams,
      {String? logPath,
      int numProcessors = 1,
      int startTime = 0,
      int endTime = -1}) async {
    final Directory tempDirectory = await getTemporaryDirectory();
    var outputPath = path.join(tempDirectory.path, "output.pcm");

    if (logPath != null) {
      cvt2PCM(inputPath, outputPath, logPath: logPath);
    } else {
      cvt2PCM(inputPath, outputPath);
    }

    Future<Float32List> _pcmf32List = pcm2List(outputPath);
    Float32List pcmf32List = await _pcmf32List;
    if (startTime != 0 || endTime != -1) {
      if (endTime == -1) {
        endTime = (pcmf32List.length / 16).toInt();
      }
      pcmf32List = pcmf32List.sublist(startTime * 16, endTime * 16);
    }

    fullParallel(wparams, pcmf32List, numProcessors);

    int nSegments = fullNSegments();
    String result = output(0, nSegments);
    return result;
  }

  Future<String> infer(String inputPath,
      {String? logPath,
      int numProcessors = 1,
      String language = "auto",
      bool translate = false,
      String initialPrompt = "",
      int strategy = whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY,
      int startTime = 0,
      int endTime = -1,
      void Function(Pointer<whisper_context>, Pointer<whisper_state>, int,
              Pointer<Void>)?
          newSegmentCallback,
      Pointer<Void>? newSegmentCallbackUserData}) async {
    var wparams = createFullDefaultParams(strategy);
    wparams.language = language.toNativeUtf8().cast<Char>();
    wparams.translate = translate;
    if (newSegmentCallback != null) {
      wparams.new_segment_callback = NativeCallable<
              Void Function(Pointer<whisper_context>, Pointer<whisper_state>,
                  Int, Pointer<Void>)>.isolateLocal(newSegmentCallback)
          .nativeFunction;
    }
    if (newSegmentCallbackUserData != null) {
      wparams.new_segment_callback_user_data = newSegmentCallbackUserData;
    }
    if (initialPrompt != "") {
      wparams.initial_prompt = initialPrompt.toNativeUtf8().cast<Char>();
    }
    return _infer(inputPath, wparams,
        logPath: logPath,
        numProcessors: numProcessors,
        startTime: startTime,
        endTime: endTime);
  }

  ValueNotifier<String> inferStream(String inputPath,
      {String? logPath,
      int numProcessors = 1,
      String language = "auto",
      bool translate = false,
      String initialPrompt = "",
      int startTime = 0,
      int endTime = -1,
      int strategy = whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY}) {
    if (outputMode == "json") {
      throw Exception("JSON output is not supported for streaming yet");
    }

    inferIsolate(inputPath,
        logPath: logPath,
        numProcessors: numProcessors,
        language: language,
        translate: translate,
        initialPrompt: initialPrompt,
        strategy: strategy,
        startTime: startTime,
        endTime: endTime,
        newSegmentCallback: getSegmentCallback);

    return result;
  }

  Future<String> inferIsolate(String inputPath,
      {String? logPath,
      int numProcessors = 1,
      String language = "auto",
      bool translate = false,
      String initialPrompt = "",
      int strategy = whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY,
      int startTime = 0,
      int endTime = -1,
      void Function(Pointer<whisper_context>, Pointer<whisper_state>, int,
              Pointer<Void>)?
          newSegmentCallback,
      Pointer<Void>? newSegmentCallbackUserData}) async {
    logPath ??= path.join((await getTemporaryDirectory()).path, "log.txt");
    var wparams = createFullDefaultParams(strategy);
    wparams.language = language.toNativeUtf8().cast<Char>();
    wparams.translate = translate;
    if (newSegmentCallback != null) {
      wparams.new_segment_callback = NativeCallable<
              Void Function(Pointer<whisper_context>, Pointer<whisper_state>,
                  Int, Pointer<Void>)>.listener(newSegmentCallback)
          .nativeFunction;
    }
    if (newSegmentCallbackUserData != null) {
      wparams.new_segment_callback_user_data = newSegmentCallbackUserData;
    }
    if (initialPrompt != "") {
      wparams.initial_prompt = initialPrompt.toNativeUtf8().cast<Char>();
    }

    // 确保 isolate 已经启动
    if (_isolateSendPort == null) {
      final ReceivePort isolateReceivePort = ReceivePort();
      bool isolateStarted = false;
      isolateReceivePort.listen((message) {
        if (message is SendPort) {
          _isolateSendPort = message;
          isolateStarted = true;
        }
      });

      await Isolate.spawn(_startInferIsolate, isolateReceivePort.sendPort);
      while (!isolateStarted) {
        await Future.delayed(Duration(milliseconds: 10));
      }
    }

    var rootToken = RootIsolateToken.instance!;
    final ReceivePort resultReceivePort = ReceivePort();
    _isolateSendPort?.send([
      inputPath,
      ctx.address,
      wparams,
      logPath,
      outputMode,
      numProcessors,
      startTime,
      endTime,
      resultReceivePort.sendPort,
      rootToken
    ]);

    return resultReceivePort.first.then((message) {
      if (message is String) {
        return message;
      } else {
        throw TypeError();
      }
    });
  }

  static void _startInferIsolate(SendPort mainSendPort) async {
    final ReceivePort isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) async {
      if (message is List && message.length == 10) {
        final String inputPath = message[0] as String;
        final int ctx = message[1] as int;
        final whisper_full_params wparams = message[2] as whisper_full_params;
        final String logPath = message[3] as String;
        final String outputMode = message[4] as String;
        final int numProcessors = message[5] as int;
        final int startTime = message[6] as int;
        final int endTime = message[7] as int;
        final SendPort resultSendPort = message[8] as SendPort;
        final RootIsolateToken rootToken = message[9] as RootIsolateToken;
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

        try {
          final String subtitle = await _inferInIsolate(inputPath, ctx, wparams,
              logPath, outputMode, numProcessors, startTime, endTime);
          resultSendPort.send(subtitle);
        } catch (e) {
          print(e);
          resultSendPort.send(e);
        }
      }
    });
  }

  static Future<String> _inferInIsolate(
      String inputPath,
      int ctx,
      whisper_full_params wparams,
      String logPath,
      String outputMode,
      int numProcessors,
      int startTime,
      int endTime) async {
    var whisperModel =
        Whisper.useCtx(Pointer.fromAddress(ctx), outputMode: outputMode);

    return whisperModel._infer(inputPath, wparams,
        logPath: logPath,
        numProcessors: numProcessors,
        startTime: startTime,
        endTime: endTime);
  }

  void close() {
    _isolateSendPort?.send(null); // 通知 isolate 退出
  }

  String output(int startSegment, int endSegment) {
    if (outputMode == "plaintext") {
      StringBuffer stringBuffer = StringBuffer();
      for (int i = startSegment; i < endSegment; ++i) {
        String text = fullGetSegmentsText(i);
        stringBuffer.write(text); // 将每段文本写入 StringBuffer
        stringBuffer.write('\n'); // 如果需要换行，可以添加换行符
      }

      String result = stringBuffer.toString(); // 获取拼接后的完整字符串

      return result;
    } else if (outputMode == "json") {
      //simplified json output
      List<Map<String, String>> result = [];
      result.add({'multilingual': isMultilingual().toString()});
      result.add({"language": langStr()});
      for (int i = startSegment; i < endSegment; i++) {
        String text = fullGetSegmentsText(i);
        result.add({
          "from": toTimestamp(fullGetSegmentT0(i)),
          "to": toTimestamp(fullGetSegmentT1(i)),
          "text": text
        });
      }

      return jsonEncode(result);
    } else if (outputMode == "txt") {
      StringBuffer stringBuffer = StringBuffer();
      for (int i = startSegment; i < endSegment; ++i) {
        String text = fullGetSegmentsText(i);
        stringBuffer.write(text); // 将每段文本写入 StringBuffer
        stringBuffer.write('\n'); // 如果需要换行，可以添加换行符
      }
      String result = stringBuffer.toString(); // 获取拼接后的完整字符串

      return result;
    } else if (outputMode == "srt") {
      StringBuffer stringBuffer = StringBuffer();
      for (int i = startSegment; i < endSegment; ++i) {
        String text = fullGetSegmentsText(i);
        stringBuffer.write("${i + 1}\n");
        stringBuffer.write(
            "${toTimestamp(fullGetSegmentT0(i), comma: true)} --> ${toTimestamp(fullGetSegmentT1(i), comma: true)}\n");
        stringBuffer.write(text); // 将每段文本写入 StringBuffer
        stringBuffer.write('\n'); // 如果需要换行，可以添加换行符
      }
      String result = stringBuffer.toString(); // 获取拼接后的完整字符串

      return result;
    } else {
      throw Exception("Invalid output mode");
    }
  }

  void getSegmentCallback(Pointer<whisper_context> ctx,
      Pointer<whisper_state> state, int nNew, Pointer<Void> userData) {
    int nSegments = fullNSegments();
    if (lastNSegments != nSegments) {
      result.value += output(lastNSegments, nSegments);
      lastNSegments = nSegments;
    }
  }
}

void cvt2PCM(String inputPath, String outputPath, {String? logPath}) {
  Map<String, String> option;
  if (logPath == null) {
    option = {
      "terminal": "yes",
      "gapless-audio": "yes",
      "o": outputPath,
      "of": "s16le",
      "oac": "pcm_s16le",
      "audio-channels": "1",
      "audio-samplerate": "16000"
    };
  } else {
    option = {
      "terminal": "yes",
      "gapless-audio": "yes",
      "log-file": logPath,
      "o": outputPath,
      "of": "s16le",
      "oac": "pcm_s16le",
      "audio-channels": "1",
      "audio-samplerate": "16000"
    };
  }
  mpv.Player player = mpv.Player(option);

  player.command(["loadfile", inputPath]);

  while (true) {
    Pointer<mpv_event> event = player.waitEvent(0);
    if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
      break;
    } else if (event.ref.event_id == mpv_event_id.MPV_EVENT_END_FILE) {
      break;
    }
  }
  player.destroy();

  print("Generated PCM file at: $outputPath");
}

Future<Float32List> pcm2List(String filePath) async {
  Uint8List pcmData = await File(filePath).readAsBytes();
  int sampleSize = 2;
  int numSamples = pcmData.length ~/ sampleSize;
  Float32List floatList = Float32List(numSamples);

  // 使用 ByteData 处理字节顺序和符号扩展
  ByteData byteData = pcmData.buffer.asByteData();
  for (int sampleIndex = 0; sampleIndex < numSamples; sampleIndex++) {
    // 假设 PCM 数据为小端字节序
    int sample = byteData.getInt16(sampleIndex * sampleSize, Endian.little);
    floatList[sampleIndex] = sample / 32768.0;
  }

  return floatList;
}

String toTimestamp(int t, {bool comma = false}) {
  int msec = t * 10; // 将输入的时间转换为毫秒
  int hr = msec ~/ (1000 * 60 * 60); // 计算小时
  msec = msec - hr * (1000 * 60 * 60);
  int min = msec ~/ (1000 * 60); // 计算分钟
  msec = msec - min * (1000 * 60);
  int sec = msec ~/ 1000; // 计算秒
  msec = msec - sec * 1000; // 剩下的毫秒部分

  // 格式化各部分数据，确保为两位或三位数字
  String hrStr = hr.toString().padLeft(2, '0');
  String minStr = min.toString().padLeft(2, '0');
  String secStr = sec.toString().padLeft(2, '0');
  String msecStr = msec.toString().padLeft(3, '0');

  // 组合字符串，根据 comma 参数选择分隔符
  return '$hrStr:$minStr:$secStr${comma ? ',' : '.'}$msecStr';
}

Pointer<Float> allocateFloatPointer(List<double> list) {
  // 分配足够的内存
  final memory = malloc<Float>(list.length);
  if (list is Float32List) {
    memory.asTypedList(list.length).setAll(0, list);

    return memory;
  }
  Float32List floatList = Float32List.fromList(list);
  // 将 list 元素复制到分配的内存中
  memory.asTypedList(floatList.length).setAll(0, floatList);

  return memory;
}

Pointer<Uint8> allocateUint8Pointer(List<int> list) {
  // 分配足够的内存
  final memory = malloc<Uint8>(list.length);
  if (list is Uint8List) {
    memory.asTypedList(list.length).setAll(0, list);

    return memory;
  }
  Uint8List uint8List = Uint8List.fromList(list);
  // 将 list 元素复制到分配的内存中
  memory.asTypedList(uint8List.length).setAll(0, uint8List);

  return memory;
}

// void newSegmentCallback(Pointer<whisper_context> ctx, Pointer<whisper_state> state,int nNew,Pointer<Void> userData){
//   var whisperModel=Whisper.useCtx(ctx);
//   var nSegments=whisperModel.fullNSegments();
//   print(whisperModel.output(nSegments-nNew,nSegments));

// }
