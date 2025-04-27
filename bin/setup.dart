import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';

Future<void> setupSrc() async {
var url = Uri.parse('https://github.com/ggerganov/whisper.cpp/archive/refs/heads/master.zip');
  var filename = 'whisper-cpp.zip';
 var packageConfig = await findPackageConfig(Directory.current);
  if (packageConfig == null) {
    print("Package config not found.");
    return;
  }
  // 查找特定插件的包信息
  var pluginPackage = packageConfig.packages.firstWhere((pkg) => pkg.name == 'whisper4dart');
  // 使用这个信息得到插件根目录
  var pluginRootPath = pluginPackage.packageUriRoot.toFilePath(windows: Platform.isWindows);
  String filePath=path.join(pluginRootPath,"..","config.txt");

  File file = File(filePath);


  try {
    if (await file.exists()) {
      // 如果文件存在，先删除文件
      await file.delete();
      
    }
    // 使用 writeAsString 方法将内容写入文件
    // 如果文件不存在，writeAsString 会自动创建文件
    await file.writeAsString('USE_PREBUILT_LIBS=FALSE');
    print('Successfully set USE_PREBUILT_LIBS=FALSE in config.txt');
  } catch (e) {
    // 捕获并处理可能发生的异常
    print(' $e');
  }
  // 下载文件
  var response = await http.get(url);
  if (response.statusCode == 200) {
    var file = File(filename);
    await file.writeAsBytes(response.bodyBytes);
    print('File downloaded and saved as $filename');

    // 读取ZIP文件
    var bytes = await file.readAsBytes();
    var archive = ZipDecoder().decodeBytes(bytes);

    // 创建新的目录来解压缩文件
    var newFolder = 'src/whisper.cpp';
    var newPath = path.join(path.dirname(pluginRootPath), newFolder);
    Directory(newPath).createSync(recursive: true);

    // 从压缩包中提取文件
    // 从压缩包中提取文件
for (var file in archive) {
  var fileName = file.name;

  // 如果是根目录下的文件夹，则跳过不解压缩
  if (file.isFile || path.split(fileName).length != 1) {
    var data = file.content as List<int>;

    // 去掉第一级目录
    List<String> pathSegments = path.split(fileName);
    if (pathSegments.isNotEmpty) {
      // 去掉第一级目录
      pathSegments.removeAt(0);
      fileName = path.joinAll(pathSegments);
    }

    var outputPath = path.join(newPath, fileName);

    // 确保父目录存在
    Directory(path.dirname(outputPath)).createSync(recursive: true);

    if (file.isFile) {
      File(outputPath)..writeAsBytesSync(data);
    } else {
      // 如果项是文件夹，则创建文件夹
      Directory(outputPath).createSync(recursive: true);
    }
    print('Extracted: $outputPath');
  }
}
    print('Files extracted to $newFolder');

    // 删除下载的ZIP文件
    await file.delete();
    print('ZIP file deleted');
  } else {
    print('Failed to download file: ${response.statusCode}');
  }
}


Future<void> setupPrebuilt() async {
var url = Uri.parse('https://github.com/KernelInterrupt/whisper4dart_build/archive/refs/heads/main.zip');
  var filename = 'whisper-prebuilt.zip';
 var packageConfig = await findPackageConfig(Directory.current);
  if (packageConfig == null) {
    print("Package config not found.");
    return;
  }
  // 查找特定插件的包信息
  var pluginPackage = packageConfig.packages.firstWhere((pkg) => pkg.name == 'whisper4dart');
  // 使用这个信息得到插件根目录
  var pluginRootPath = pluginPackage.packageUriRoot.toFilePath(windows: Platform.isWindows);
 String filePath=path.join(pluginRootPath,"..","config.txt");

  File file = File(filePath);

  try {
    if (await file.exists()) {
      // 如果文件存在，先删除文件
      await file.delete();
      
    }
    // 使用 writeAsString 方法将内容写入文件
    // 如果文件不存在，writeAsString 会自动创建文件
    await file.writeAsString('USE_PREBUILT_LIBS=TRUE');
    print('Successfully set USE_PREBUILT_LIBS=TRUE in config.txt');
  } catch (e) {
    // 捕获并处理可能发生的异常
    print(' $e');
  }
  // 下载文件
  var response = await http.get(url);
  if (response.statusCode == 200) {
    var file = File(filename);
    await file.writeAsBytes(response.bodyBytes);
    print('File downloaded and saved as $filename');

    // 读取ZIP文件
    var bytes = await file.readAsBytes();
    var archive = ZipDecoder().decodeBytes(bytes);

    // 创建新的目录来解压缩文件
    var newFolder = 'prebuilt';
    var newPath = path.join(path.dirname(pluginRootPath), newFolder);
    Directory(newPath).createSync(recursive: true);

    // 从压缩包中提取文件
    // 从压缩包中提取文件
for (var file in archive) {
  var fileName = file.name;

  // 如果是根目录下的文件夹，则跳过不解压缩
  if (file.isFile || path.split(fileName).length != 1) {
    var data = file.content as List<int>;

    // 去掉第一级目录
    List<String> pathSegments = path.split(fileName);
    if (pathSegments.isNotEmpty) {
      // 去掉第一级目录
      pathSegments.removeAt(0);
      fileName = path.joinAll(pathSegments);
    }

    var outputPath = path.join(newPath, fileName);

    // 确保父目录存在
    Directory(path.dirname(outputPath)).createSync(recursive: true);

    if (file.isFile) {
      File(outputPath)..writeAsBytesSync(data);
    } else {
      // 如果项是文件夹，则创建文件夹
      Directory(outputPath).createSync(recursive: true);
    }
    print('Extracted: $outputPath');
  }
}
    print('Files extracted to $newFolder');

    // 删除下载的ZIP文件
    await file.delete();
    print('ZIP file deleted');
    var iosPath=path.join(pluginRootPath,"..","ios");
    var macosPath=path.join(pluginRootPath,"..","macos");
  var frameworkPath=path.join(newPath,"apple");
  copyFiles(frameworkPath, iosPath);
  copyFiles(frameworkPath, macosPath);
  
  } else {
    print('Failed to download file: ${response.statusCode}');
  }


}

void copyFiles(String sourceDirPath, String targetDirPath) {
  // 获取源目录对象
  Directory sourceDir = Directory(sourceDirPath);
  // 获取目标目录对象
  Directory targetDir = Directory(targetDirPath);

  // 检查源目录是否存在
  if (!sourceDir.existsSync()) {
    print('源目录不存在！');
    return;
  }

  // 如果目标目录不存在，则创建目标目录
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  // 遍历源目录中的所有文件和子目录
  for (FileSystemEntity entity in sourceDir.listSync()) {
    // 如果是文件，则复制文件
    if (entity is File) {
      File file = entity;
      String fileName = file.path.split('/').last;
      File targetFile = File('${targetDir.path}/$fileName');
      file.copySync(targetFile.path);
    }
    // 如果是目录，则递归调用此函数拷贝子目录
    else if (entity is Directory) {
      String subDirName = entity.path.split('/').last;
      copyFiles(entity.path, '${targetDir.path}/$subDirName');
    }
  }
}


void main(List<String> arguments) async {
  print('Setting up whisper4dart...');
  String command = arguments[0];
  if(command=="--source"){
    setupSrc();
    print('Attention: In current version of whisper4dart, even though you have set it to use source code compilation, the Android iOS and MacOS platform will still automatically use precompiled libraries. This will be changed in a later version.');
  }
  else if(command=="--prebuilt"){
    setupPrebuilt();
  }

}