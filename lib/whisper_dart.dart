
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:libmpv_dart/gen/bindings.dart';
import 'package:libmpv_dart/libmpv.dart' as mpv;

import 'package:path_provider/path_provider.dart';
import 'package:whisper_dart/library.dart';
import 'package:whisper_dart/other.dart';
import 'whisper_dart_bindings_generated.dart';


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





class Whisper{


late Pointer<whisper_context> ctx;
int get handle => ctx.address;

Whisper(String modelPath,whisper_context_params cparams){
  if (!WhisperLibrary.loaded) {
      if (!WhisperLibrary.flagFirst) {
        WhisperLibrary.init();
      } else {
        throw Exception('libwhisper is not loaded!');
      }
    }
  ctx=WhisperLibrary.binding.whisper_init_from_file_with_params(modelPath.toNativeUtf8().cast<Char>(), cparams);

}

void full(whisper_full_params wparams,List<double> pcmf32List){
 
        Pointer<Float> pcmf32=allocateFloatPointer(pcmf32List);
        if (WhisperLibrary.binding.whisper_full(ctx, wparams, pcmf32, pcmf32List.length) != 0) {
          throw Exception("failed to process audio");
        }
      
}

void fullParallel(whisper_full_params wparams,List<double> pcmf32List,int nProcessors){
 
        Pointer<Float> pcmf32=allocateFloatPointer(pcmf32List);
        if (WhisperLibrary.binding.whisper_full_parallel(ctx, wparams, pcmf32, pcmf32List.length,nProcessors) != 0) {
          throw Exception("failed to process audio");
        }
      
}
int fullNSegments(){
  return WhisperLibrary.binding.whisper_full_n_segments(ctx);
}

String fullGetSegmentsText(int i){
  return WhisperLibrary.binding.whisper_full_get_segment_text(ctx, i).cast<Utf8>().toDartString();

}

String printSystemInfo(){
  return WhisperLibrary.binding.whisper_print_system_info().cast<Utf8>().toDartString();
}

void free(){
  return WhisperLibrary.binding.whisper_free(ctx);
}
}


void cvt2PCM(String inputPath,String outputPath){
Map<String,String> option={
"terminal":"yes",
"gapless-audio":"yes",
"o":outputPath,
"of":"s16le",
"oac":"pcm_s16le"
};

  mpv.Player player = mpv.Player(option);
 player.command(["loadfile",inputPath]);
 

 while(true){
   Pointer<mpv_event> event=player.waitEvent(0);
if(event.ref.event_id==mpv_event_id.MPV_EVENT_SHUTDOWN){
break;
}
else if(event.ref.event_id==mpv_event_id.MPV_EVENT_END_FILE){
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
  if(list is Float32List){
    memory.asTypedList(list.length).setAll(0, list);
 
    return memory;
  }
Float32List floatList=Float32List.fromList(list);
  // 将 list 元素复制到分配的内存中
  memory.asTypedList(floatList.length).setAll(0, floatList);

  return memory;
}

void minimumInferenceImpl(String inputPath) async{
    // Basic usage:
    //     whisper_context_params cparams = whisper_context_default_params();
    //
    //     struct whisper_context * ctx = whisper_init_from_file_with_params("/path/to/ggml-base.en.bin", cparams);
    //
    //     if (whisper_full(ctx, wparams, pcmf32.data(), pcmf32.size()) != 0) {
    //         fprintf(stderr, "failed to process audio\n");
    //         return 7;
    //     }
    //
    //     const int n_segments = whisper_full_n_segments(ctx);
    //     for (int i = 0; i < n_segments; ++i) {
    //         const char * text = whisper_full_get_segment_text(ctx, i);
    //         printf("%s", text);
    //     }
    //
    //     whisper_free(ctx);
Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path+"/tempfile.pcm";
var cparams=createContextDefaultParams();
var wparams=createFullDefaultParams(whisper_sampling_strategy.WHISPER_SAMPLING_GREEDY);
var whisper=Whisper("model/ggml-base.en.bin", cparams);
cvt2PCM(inputPath, tempPath);
Future<Float32List> _pcmf32List=pcm2List(tempPath);
Float32List pcmf32List=await _pcmf32List;
whisper.fullParallel(wparams,pcmf32List,1);
        
int n_segments = whisper.fullNSegments();
print(whisper.printSystemInfo());
print("Number of segments: $n_segments");
        for (int i = 0; i < n_segments; ++i) {
            String text = whisper.fullGetSegmentsText(i);
            print(text);
        }
  whisper.free();
}




