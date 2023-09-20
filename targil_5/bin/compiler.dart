import 'dart:io';

import 'Entities.dart';
import 'Parser.dart';
import 'tokenizing.dart';
import 'SymbolTable.dart';

class Compiler {
  final TokenNode root;
  final SymbolTable classSymbolTable = SymbolTable();
  var labelsCounter = 0;
  var className;
  var vmCode;

  Compiler(this.root);

  get op => {
        '+': 'add\n',
        '-': 'sub\n',
        '*': 'call Math.multiply 2\n',
        '/': 'call Math.divide 2\n',
        '&amp;': 'and\n',
        '|': 'or\n',
        '&lt;': 'lt\n',
        '&gt;': 'gt\n',
        '=': 'eq\n'
      };

  get keyConstAndUnarOp => {
        '-': 'neg\n',
        '~': 'not\n',
        'true': 'push constant 0\n' 'not\n',
        'false': 'push constant 0\n',
        'null': 'push constant 0\n',
        'this': 'push pointer 0\n'
      };

  generateCode() {
    className = root.sons![1].token!.value;
    this.vmCode = _generateCodeNode(root);
    return vmCode;
  }

  _generateCodeNode(TokenNode tokenNode, {SymbolTable? subroutineSymbolTable = null}) {
    var vmCode = '';
    switch (tokenNode.grammar) {

      // root code
      case Grammar.$class:
        for (var node in tokenNode.sons  ?? []) {
          vmCode += _generateCodeNode(node);
        }
        break;

      // insert the class variables (fields and static) to a symbol table
      case Grammar.classVarDec:
        _insertClassVar(tokenNode);
        break;
      // function void main()....
      case Grammar.subroutineDec:
        var name = tokenNode.sons![2].token!.value;
        var numLocals = _getLocalLength(tokenNode.sons![6]);
        var numFields = classSymbolTable.table.where((entry) => entry.segment == 'this').length;
        var withThis = false;
        vmCode = 'function $className.$name $numLocals\n';
        if (tokenNode.sons![0].token!.value == 'method') {
          vmCode += 'push argument 0\n'
              'pop pointer 0\n';
          withThis = true;
        } else if (tokenNode.sons![0].token!.value == 'constructor') {
          vmCode += 'push constant $numFields\n'
              'call Memory.alloc 1\n'
              'pop pointer 0\n';
        }
        vmCode +=
            _generateCodeNode(tokenNode.sons![6], subroutineSymbolTable: _getParamsTable(tokenNode.sons![4], withThis));
        break;
      case Grammar.integerConstant:
        vmCode = 'push constant ${tokenNode.token!.value}\n';
        break;
      case Grammar.stringConstant:
        vmCode = 'push constant ${tokenNode.token!.value.length}'
            'call String.new 1\n';
        tokenNode.token!.value.split('').forEach((char) => {vmCode += char.codeUnitAt(0).toString()});
        break;
      case Grammar.subroutineBody:
        // insert all vars in the func body to the table
        tokenNode.sons!
            .where((son) => son.grammar == Grammar.varDec)
            .forEach((varDec) => {_insertSubroutineVar(varDec, subroutineSymbolTable!)});
        vmCode = _generateCodeNode(tokenNode.sons!.firstWhere((son) => son.grammar == Grammar.statements),
            subroutineSymbolTable: subroutineSymbolTable);
        break;
      case Grammar.statements:
        tokenNode.sons!
            .forEach((son) => {vmCode += _generateCodeNode(son, subroutineSymbolTable: subroutineSymbolTable)});
        break;
      case Grammar.letStatement:
        var varName = tokenNode.sons![1].token!.value;
        //search for the variable in the function table first then at the class table 
        SymbolEntry symbolEntry = subroutineSymbolTable!.exist(varName)
            ? subroutineSymbolTable.findByName(varName)
            : classSymbolTable.findByName(varName);
        var offset = symbolEntry.offset;
        var segment = symbolEntry.segment;
        if (tokenNode.sons![2].token!.value == '[') {
          //puts first the right side of the let statements
          vmCode = _generateCodeNode(tokenNode.sons![6], subroutineSymbolTable: subroutineSymbolTable);
          vmCode += _generateCodeNode(tokenNode.sons![3], subroutineSymbolTable: subroutineSymbolTable);
          vmCode += 'push $segment $offset\n' 
              'add\n' //adds the constant to the array address
              'pop pointer 1\n'//puts the address he found into "that"
              'pop that 0\n'; //puts the right side of the statement into address 
        } else {
          vmCode = _generateCodeNode(tokenNode.sons![3], subroutineSymbolTable: subroutineSymbolTable);
          vmCode += 'pop $segment $offset\n';
        }
        break;
      case Grammar.ifStatement:
        vmCode += _generateCodeNode(tokenNode.sons![2], subroutineSymbolTable: subroutineSymbolTable);
        var labelNumber = labelsCounter++;
        vmCode += 'if-goto IF_TRUE$labelNumber\n' //checks the top value on the stack and jumps to the label 'IF_TRUE$labelNumber' 
            'goto IF_FALSE$labelNumber\n'
            'label IF_TRUE$labelNumber\n';
          //generate the body of the if
        vmCode += _generateCodeNode(tokenNode.sons![5], subroutineSymbolTable: subroutineSymbolTable);
        //checks if therers an else statement
        if (tokenNode.sons!.length > 7) {
          vmCode += 'goto IF_End$labelNumber\n'
              'label IF_FALSE$labelNumber\n';
          vmCode += _generateCodeNode(tokenNode.sons![9], subroutineSymbolTable: subroutineSymbolTable) +
              'label IF_End$labelNumber\n';
        } 
        else {
          vmCode += 'label IF_FALSE$labelNumber\n';
        }
        break;
      case Grammar.whileStatement:
        var labelNum = labelsCounter++;
        vmCode += 'label START_WHILE$labelNum\n';
        //generate condition
        vmCode += _generateCodeNode(tokenNode.sons![2], subroutineSymbolTable: subroutineSymbolTable);
        vmCode += 'not\n' 'if-goto WHILE_END$labelNum\n';
        //generate body of while
        vmCode += _generateCodeNode(tokenNode.sons![5], subroutineSymbolTable: subroutineSymbolTable);
        vmCode += 'goto START_WHILE$labelNum\n'
            'label WHILE_END$labelNum\n';
        break;
      case Grammar.doStatement:
        tokenNode.sons!.removeAt(0);
        vmCode += _subroutineCallCode(tokenNode, subroutineSymbolTable!);
        vmCode += 'pop temp 0\n';
        break;
      case Grammar.returnStatement:
        TokenNode? subroutineDec = tokenNode.father;
        //search for the declaration of the function
        while (subroutineDec!.grammar != Grammar.subroutineDec) {
          subroutineDec = subroutineDec.father;
        }
        var funcType = subroutineDec.sons![0].token!.value;
        var funcReturnType = subroutineDec.sons![1].token!.value;
        if (funcType == 'constructor' || funcReturnType == 'void') {
          vmCode += 'push pointer 0\n'
              'return\n';
        } else {
          vmCode += _generateCodeNode(tokenNode.sons![1], subroutineSymbolTable: subroutineSymbolTable) + 'return\n';
        }
        subroutineSymbolTable = null;
        break;
      case Grammar.expression:
        for (var i = 0; i < tokenNode.sons!.length; i++) {
          if (tokenNode.sons![i].grammar == Grammar.term) {
            //generates both terms and then the operator
            vmCode += _generateCodeNode(tokenNode.sons![i], subroutineSymbolTable: subroutineSymbolTable);
          } else {
            vmCode += _generateCodeNode(tokenNode.sons![i + 1], subroutineSymbolTable: subroutineSymbolTable);
            vmCode += op[tokenNode.sons![i].token!.value];
            i++;
          }
        }
        break;
      case Grammar.term:
        switch (tokenNode.sons!.first.grammar) {
          // integerConstant
          case Grammar.integerConstant:
            vmCode += 'push constant ${tokenNode.sons!.first.token!.value}\n';
            break;
          // keywordConstant
          case Grammar.keyword:
            vmCode += keyConstAndUnarOp[tokenNode.sons!.first.token!.value];
            break;
          // ( expression ) | unaryOp term
          case Grammar.symbol:
            vmCode += _generateCodeNode(tokenNode.sons![1], subroutineSymbolTable: subroutineSymbolTable);
            if (tokenNode.sons!.first.token!.value != '(') {
              vmCode += keyConstAndUnarOp[tokenNode.sons!.first.token!.value];
            }
            break;
          // stringConstant
          case Grammar.stringConstant:
            var strLen = tokenNode.sons!.first.token!.value.length;
            vmCode += 'push constant $strLen\n' 'call String.new 1\n';
            //for each char in the string, appends it to the others
            for (var char in tokenNode.sons!.first.token!.value.codeUnits) {
              vmCode += 'push constant $char\n' 'call String.appendChar 2\n';
            }
            break;
          // varName | varName[expression] | subroutineCall
          default:
            var name = tokenNode.sons!.first.token!.value;
            // varName
            if (tokenNode.sons!.length == 1) {
              var varName = subroutineSymbolTable!.exist(name)
                  ? subroutineSymbolTable.findByName(name)
                  : classSymbolTable.findByName(name);
              vmCode += 'push ${varName.segment} ${varName.offset}\n';
            }
            // varName[expression]
            else if (tokenNode.sons![1].token!.value == '[') {
              var varName = subroutineSymbolTable!.exist(name)
                  ? subroutineSymbolTable.findByName(name)
                  : classSymbolTable.findByName(name);
              vmCode += _generateCodeNode(tokenNode.sons![2], subroutineSymbolTable: subroutineSymbolTable);
              vmCode += 'push ${varName.segment} ${varName.offset}\n'
                  'add\n'
                  'pop pointer 1\n'
                  'push that 0\n';
            }
            // subroutineCall
            else {
              vmCode += _subroutineCallCode(tokenNode, subroutineSymbolTable!);
            }
            break;
        }
        break;
      case Grammar.expressionList:
        if (tokenNode.sons == null) break;
        for (var node in tokenNode.sons  ?? []) {
          if (node.grammar == Grammar.expression) {
            vmCode += _generateCodeNode(node, subroutineSymbolTable: subroutineSymbolTable);
          }
        }
        break;
      default:
        break;
    }
    return vmCode;
  }

  //inserts all the variables of the class into the symbol table
  _insertClassVar(TokenNode classVarDekNode) {
    var segment = classVarDekNode.sons![0].token!.value;
    if (segment == 'field') {
      segment = 'this';
    }
    var type = classVarDekNode.sons![1].token!.value;
    classVarDekNode.sons!.sublist(2).forEach((token) => {
          if (token.token!.type == TokenType.identifier) {classSymbolTable.add(token.token!.value, type, segment)}
        });
  }
  //counts the number of variables of a function/method 
  _getLocalLength(TokenNode subroutineBody) {
    return subroutineBody.sons!
        .where((son) => son.grammar == Grammar.varDec)
        .map((varDec) => (varDec.sons!.length - 2) / 2)
        .fold<int>(0, (acc, item) => acc + item.floor());
  }
  //create a table for the arguments next function/constructor/method
  _getParamsTable(TokenNode parameterList, bool withThis) {
    SymbolTable table = SymbolTable();
    if (parameterList.sons == null) {
      return table;
    }
    if (withThis) {
      table.add('this', className, 'argument');
    }
    for (var i = 0; i < parameterList.sons!.length; i += 3) {
      table.add(parameterList.sons![i + 1].token!.value, parameterList.sons![i].token!.value, 'argument');
    }
    return table;
  }
  //inserts into the subrutine table a variable : 'var int a, b...'
  void _insertSubroutineVar(TokenNode tokenNode, SymbolTable subroutineSymbolTable) {
    var type = tokenNode.sons![1].token!.value;
    tokenNode.sons!.sublist(2).forEach((token) => {
          if (token.token!.type == TokenType.identifier) {subroutineSymbolTable.add(token.token!.value, type, 'local')}
        });
  }

  // generate subroutine call
  String _subroutineCallCode(TokenNode tokenNode, SymbolTable subroutineSymbolTable) {
    var vmCode = '';
    // expressionList node
    var expList = tokenNode.sons!.firstWhere((son) => son.grammar == Grammar.expressionList);
    // number of args
    var argLength = expList.sons != null ? ((expList.sons!.length + 1) / 2).floor() : 0;
    // generate the code that push all params
    var pushArgs = _generateCodeNode(expList, subroutineSymbolTable: subroutineSymbolTable);
    // the name of function or the class or variable
    var funcClassVarName = tokenNode.sons!.first.token!.value;
    // subroutineName(expressionList)- method
    if (tokenNode.sons![1].token!.value != '.') {
      vmCode += 'push pointer 0\n' + pushArgs + 'call $className.$funcClassVarName ${argLength + 1}\n';
    }
    // varName.subroutineName(expressionList) - function
    //finds the object  that calls the function
    else if (subroutineSymbolTable.exist(funcClassVarName) || classSymbolTable.exist(funcClassVarName)) {
      var entry = subroutineSymbolTable.exist(funcClassVarName)
          ? subroutineSymbolTable.findByName(funcClassVarName)
          : classSymbolTable.findByName(funcClassVarName);
      vmCode += 'push ${entry.segment} ${entry.offset}\n' +
          pushArgs +
          'call ${entry.type}.${tokenNode.sons![2].token!.value} ${argLength + 1}\n'; //type is the name of the class
    }
    // className.subroutineName(expressionList) - static function
    else {
      vmCode += pushArgs + 'call $funcClassVarName.${tokenNode.sons![2].token!.value} $argLength\n';
    }
    return vmCode;
  }

  //writes the vm code into a file
  Future exportVmCode(String filePath) async {
    var file = File(filePath);
    await file.writeAsString(vmCode);
  }
}

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
      var fileName = filePath.substring(filePath.lastIndexOf('\\') + 1);
      var jackCode = File(entity.path).readAsStringSync();
      var tokenizer = Tokenizer(jackCode);
      print('$fileName generate tokens...');
      tokenizer.generateTokens();
      print('$fileName parsing...');
      var parser = Parser(tokenizer.outputTokenList);
      parser.parse();
      print('$fileName compiling...');
      var compiler = Compiler(parser.root);
      compiler.generateCode();
      print('export $fileName.vm file...');
      compiler.exportVmCode('$filePath.vm').then((onValue) => print('$fileName.vm exported...'));
      // print('$fileName .... FINISH ....');
    }
  });
}