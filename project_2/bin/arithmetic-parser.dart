class ArithmeticCommands {
  static const _PREFIX_BINARY_OPERATOR =
      '@SP\n' + 'AM=M-1\n' + 'D=M\n' + 'A=A-1\n';

  static const add = _PREFIX_BINARY_OPERATOR + 'M=D+M\n';
  static const sub = _PREFIX_BINARY_OPERATOR + 'M=M-D\n';
  static const neg = '@SP\n' + 'A=M-1\n' + 'M=-M\n';

  static const and = _PREFIX_BINARY_OPERATOR + 'M=D&M\n';
  static const or = _PREFIX_BINARY_OPERATOR + 'M=D|M\n';
  static const not = '@SP\n' + 'A=M-1\n' + 'M=!M\n';

  final _rout_map =
  {
    'add': add,
    'sub': sub,
    'neg': neg,
    'and': and,
    'or': or,
    'not': not
  };

  parse(line) {
    return _rout_map[line];
  }
}