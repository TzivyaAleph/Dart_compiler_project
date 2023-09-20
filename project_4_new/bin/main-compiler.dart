import 'dart:io';
import 'Parser.dart';
import 'tokenizing.dart';

main() {
  print('Enter folder path');
  var directoryPath = stdin.readLineSync();
  var directory = new Directory(directoryPath!);
  if (!directory.existsSync()) {
    print('this directory not found');
    return;
  }
  directory.list(recursive: true).forEach((FileSystemEntity entity) {
    if (entity.path.endsWith('.jack')) {
      var filePath = entity.path.substring(0, entity.path.length - 5);
      var fileName = filePath.substring(filePath.lastIndexOf('\\')+1);
      var jackCode = File(entity.path).readAsStringSync();
      var tokenizer = Tokenizer(jackCode);
      print('$fileName generate tokens...');
      tokenizer.generateTokens();
      print('$fileName export to xml file \'${filePath}T.xml\'...');
      tokenizer.exportFileToXML(filePath);
      print('$fileName compile...');
      var compiler = Parser(tokenizer.outputTokenList);
      compiler.parse();
      print('$fileName exporte to xml file \'${filePath}.xml\'...');
      compiler.exportToXml(filePath);
      print('$fileName .... FINISH ....');
    }
  });
}

