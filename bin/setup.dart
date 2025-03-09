import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';

Future<void> setup() async {
var url = Uri.parse('https://github.com/ggerganov/whisper.cpp/archive/refs/heads/master.zip');
  var filename = 'whisper-cpp.zip';
 var packageConfig = await findPackageConfig(Directory.current);
  if (packageConfig == null) {
    print("Package config not found.");
    return;
  }
  // 查找特定插件的包信息
  var pluginPackage = packageConfig.packages.firstWhere((pkg) => pkg.name == 'whisper_dart');
  // 使用这个信息得到插件根目录
  var pluginRootPath = pluginPackage.packageUriRoot.toFilePath(windows: Platform.isWindows);
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






void main(List<String> arguments) async {
  print('Setting up whisper_dart...');
setup();
}