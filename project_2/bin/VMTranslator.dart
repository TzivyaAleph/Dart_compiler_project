import 'arithmetic-parser.dart';
import 'logic-parser.dart';
import 'memory-access-parser.dart';
import 'flow-commands.dart';
import 'functions-commands.dart';

import 'dart:io';
import 'dart:convert';

class _VMTranslatorFile {
  final memoryReg = new RegExp(
      r'^(pop|push) (local|argument|this|that|constant|temp|pointer|static) \d+([ \t])*(//(.)*)*$');
  final arithmeticReg = new RegExp(r'^(add|sub|neg|and|or|not)([ \t])*(//(.)*)*$');
  final logicReg = new RegExp(r'^(eq|gt|lt)([ \t])*(//(.)*)*$');
  final flowReg = new RegExp(r'^(label|goto|if-goto) (\w|\.)+([ \t])*(//(.)*)*$');
  final functionsReg =
      new RegExp(r'^(return|(call|function) (\w|\.)+ \d+)([ \t])*(//(.)*)*$');

  ArithmeticCommands arithmeticParser = new ArithmeticCommands();
  LogicCommands logicParser = new LogicCommands();
  MemoryAccessCommands memoryParser = new MemoryAccessCommands("");
  FlowCommands flowParser = new FlowCommands("");
  FunctionCommands functionParser = new FunctionCommands("");

  var _fileName;

  _VMTranslatorFile(String fileName) {
    _fileName = fileName;
    arithmeticParser = new ArithmeticCommands();
    logicParser = new LogicCommands();
    memoryParser = new MemoryAccessCommands(_fileName);
    flowParser = new FlowCommands(_fileName);
    functionParser = new FunctionCommands(_fileName);
  }

  
  String parseFile(List<String> listOfLines) {
    var hackCode = '';
    for (var line in listOfLines) {
      hackCode += _parseCommand(line);
    }
    return hackCode;
  }

  String _parseCommand(String line) {
    var type = _CheckTypeCommand(line);
    var cleanLine = line;
    if (line.contains('//')) {
      cleanLine = line.substring(0, line.indexOf('//'));
    }
    cleanLine = cleanLine.replaceAll('\t', ' ');
    while (cleanLine.endsWith(' ')) {
      cleanLine = cleanLine.substring(0, cleanLine.length - 1);
    }

    switch (type) {
      case 'comment':
      case 'empty':
        return '';
      case 'arithmetic':
        return arithmeticParser.parse(cleanLine);
      case 'memory':
        return memoryParser.parse(cleanLine);
      case 'logic':
        return logicParser.parse(cleanLine);
      case 'flow':
        return flowParser.parse(cleanLine);
      case 'function':
        return functionParser.parse(cleanLine);
      default:
        throw '${line}\ncommand not valid';
    }
  }

  _CheckTypeCommand(String line) {
    if (line.startsWith('//')) return 'comment';
    if (line == '') return 'empty';
    if (arithmeticReg.hasMatch(line)) return 'arithmetic';
    if (memoryReg.hasMatch(line)) return 'memory';
    if (logicReg.hasMatch(line)) return 'logic';
    if (flowReg.hasMatch(line)) return 'flow';
    if (functionsReg.hasMatch(line)) return 'function';
    return 'not valid';
  }
}

var _bootstrap = '@256\n' 'D=A\n' '@SP\n' 'M=D\n' + FunctionCommands('').parse('call Sys.init 0');

class VMTranslator {
  translate(String directoryPath) async {
    List<String> listHacks = <String>[];
    var directory = new Directory(directoryPath);
    if (!directory.existsSync()) {
      print('this directory not found');
      return;
    }
    var bootstrap = '';
    var dirName = directoryPath.substring(directoryPath.lastIndexOf('\\')+1);
    await directory.list(recursive: true).forEach((FileSystemEntity entity) {
      if (entity.path.endsWith('.vm')) {
        var fileName = entity.path.replaceFirst(directoryPath, dirName)
            .substring(0,entity.path.replaceFirst(directoryPath, dirName).length -3)
            .replaceAll('\\', '.');
        var translator = new _VMTranslatorFile(fileName);
        List<String> lines = (entity as File).readAsLinesSync();
        listHacks.add(translator.parseFile(lines));
        if(fileName.endsWith('.Sys')){
          bootstrap = _bootstrap;
        }
      }
    });

    directoryPath = directoryPath + "\\" + dirName;
    var hackFile = new File(directoryPath + '.asm').openWrite();
    hackFile.write(bootstrap + listHacks.join('\n//----- file -----\n'));
  }
}

main() async {
  print("enter the directory path");
  var path = stdin.readLineSync();
  VMTranslator vmTranslator = new VMTranslator();
  await vmTranslator.translate(path!);
  print('-------- end ---------');
}