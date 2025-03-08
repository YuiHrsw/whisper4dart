# whisper_dart

Whisper_dart is a dart wrapper for [whisper.cpp](https://github.com/ggerganov/whisper.cpp), designed to offer an all-in-one speech recognition experience. With the built-in decoder/demuxer from ffmpeg, it can handle **most audio file** inputs, not just wav.

## Getting Started

```powershell
flutter pub add whisper_dart
```

or add following line to your `pubspec.yaml`:

```
    whisper_dart:^0.0.1
```

After that,run following command in your terminal:

```
dart rum libmpv_dart:setup --platform <your-platform>
```

At this point,`whisper_dart ` is only available for Android,Windows and Linux.

For example,you need to run:`dart rum libmpv_dart:setup --platform windows` if you want to setup for windows.

## How to use

```dart
final Directory tempDirectory = await getTemporaryDirectory();
final ByteData documentBytes = await rootBundle.load(inputPath);
await File(inputPath).writeAsBytes(
    documentBytes.buffer.asUint8List(),
);
//preprocess the file,if the file is not in assets/ ,you don't need to use the code above.

final String logPath = '${tempDirectory.path}/log.txt';


var cparams=whisper_dart.createContextDefaultParams();
//create default parameters,you can modify it on your demand.

var buffer=await rootBundle.load("assets/ggml-base.en.bin");
Uint8List model=buffer.buffer.asUint8List();
//if your model file is not in assets/ ,you dont need to do so,
//and you just need to pass the file path of model to initialize whisper.
//Like this:	var model="path/to/your/model";

var whisper=whisper_dart.Whisper(model,cparams);
//initialize whisper model
return whisper.infer(inputPath,logPath: logPath,outputMode: "srt",numProcessors: 1);
//whisper.infer is the core function,"inputPath" is the file path of the audio file(for example:/tmp/jfk.mp3),
//After you specify "logPath", whisper_dart will output the encoder/demuxer logs to that directory.
//The "outputMode" variable determines the output format. There are four options:
//"plaintext": Outputs plain text
//"txt": Outputs text-formatted strings
//"json": Outputs JSON-formatted strings
//"srt": Outputs SRT-subtitle-formatted strings
```

Sample output strings of the four output modes:(input file:jfk.wav)

`plaintext`:

```
 And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country.
```

`txt`:

```
 And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country.
```

`json`:

```json
[{"multilingual":"false"},{"language":"en"},{"from":"00:00:00.000","to":"00:00:11.000","text":" And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country."}]
```

`srt`:

```
1
00:00:00,000 --> 00:00:11,000
 And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country.
```


## Acknowledgement

This project leverages contributions from[ libmpv_dart ](https://github.com/Playboy-Player/libmpv_dart)and [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
