class FlowCommands {
  final String _fileName;

  FlowCommands(this._fileName);

  _label(label) {
    return '(${_fileName}.${label})\n';
  }

  _goto(label) {
    return '@${_fileName}.${label}\n'
        '0; JMP\n';
  }

  _if_goto(label) {
    return '@SP\n'
        'AM=M-1\n'
        'D=M\n'
        '@${_fileName}.${label}\n'
        'D;JNE\n';
  }

  parse(String line) {
    var command=line.split(' ');
    switch(command[0])
    {
      case 'label':
        return _label(command[1]);
      case 'goto':
        return _goto(command[1]);
      case 'if-goto':
        return _if_goto(command[1]);

    }
  throw '${line}\nflow command not valid ';
  }
}