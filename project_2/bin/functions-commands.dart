import 'memory-access-parser.dart';

class FunctionCommands {
  final String _fileName;
  MemoryAccessCommands memAccess = new MemoryAccessCommands("");

  static var _returnAddressCounter = 0;
  static var _funcLoopCounter = 0;

  FunctionCommands(this._fileName) {
    memAccess = new MemoryAccessCommands(_fileName);
  }

  _push(val) {
    return memAccess.push('constant', val);
  }

  _pushSegment(segment)
   {
    return '@${segment}\n'
        'D=M\n'
        '@SP\n'
        'M=M+1\n'
        'A=M-1\n'
        'M=D\n';
  }

  _popSegment(Segment) {
    return '@LCL\n'
        'AM=M-1\n'
        'D=M\n'
        '@${Segment}\n'
        'M=D\n';
  }

  _call(funcName, nArgs) {
    return  this._push('RA${_returnAddressCounter}') +
        this._pushSegment('LCL') +
        this._pushSegment('ARG') +
        this._pushSegment('THIS') +
        this._pushSegment('THAT') +
        '@SP\n' 
        'D=M\n'
        '@${int.parse(nArgs) + 5}\n'
        'D=D-A\n'
        '@ARG\n'
        'M=D\n' 
        '@SP\n'
        'D=M\n'
        '@LCL\n'
        'M=D\n'
        '@${funcName}\n'
        '0;JMP\n'
        '(RA${_returnAddressCounter++})\n';
  }
  //pushes n zeroes into the stack for n locals
  _function(funcName, nArgs) {
    return '(${funcName})\n'
        '@${nArgs}\n'
        'D=A\n'
        '@${funcName}.END.${_funcLoopCounter}\n'
        'D;JEQ\n'
        '(${funcName}.Loop.${_funcLoopCounter})\n'
        '@SP\n'
        'A=M\n'
        'M=0\n'
        '@SP\n'
        'M=M+1\n'
        '@${funcName}.Loop.${_funcLoopCounter}\n'
        'D=D-1;JNE\n'
        '(${funcName}.END.${_funcLoopCounter})\n';
  }

  _return() {
    return  '@5\n'
        'D=A\n'
        '@LCL\n'
        'A=M-D\n'
        'D=M\n'
        '@13\n'
        'M=D\n'
        '@SP\n'
        'A=M-1\n'
        'D=M\n'
        '@ARG\n'
        'A=M\n'
        'M=D\n'
        '@ARG\n'
        'D=M+1\n'
        '@SP\n'
        'M=D\n' +
        _popSegment('THAT') +
        _popSegment('THIS') +
        _popSegment('ARG') +
        _popSegment('LCL') +
        '@13\n'
        'A=M\n'
        '0;JMP\n';
  }

  parse(String line) {
    var command = line.split(' ');
    switch (command[0]) {
      case 'call':
        return _call(command[1], command[2]);
      case 'function':
        return _function(command[1], command[2]);
      case 'return':
        return _return();
    }
    throw '${line}\nfunction command not valid';
  }
}