import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:whisper_dart/whisper_dart.dart' as whisper_dart;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
void main() {
  
  runApp(const MyApp());
}

Future<String> inference(String inputPath) async{
   
final Directory tempDirectory = await getTemporaryDirectory();
final ByteData documentBytes = await rootBundle.load(inputPath);


final String logPath = '${tempDirectory.path}/log.txt';
await File(inputPath).writeAsBytes(
    documentBytes.buffer.asUint8List(),
);
var buffer=await rootBundle.load("assets/ggml-base.en.bin");
Uint8List model=buffer.buffer.asUint8List();
var cparams=whisper_dart.createContextDefaultParams();
var whisper=whisper_dart.Whisper(model,cparams);
return whisper.infer(inputPath,logPath: logPath,outputMode: "srt",numProcessors: 1);

}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  

  @override
  void initState() {
    super.initState();
   
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                ElevatedButton(onPressed:()async{
                  
                  print(await inference("assets/jfk.wav"));},child: spacerSmall,),
                spacerSmall,
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
