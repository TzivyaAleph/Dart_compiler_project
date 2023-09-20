class LogicCommands {
  static const _PREFIX_BINARY_OPERATOR =
      '@SP\n' + 'AM=M-1\n' + 'D=M\n' + 'A=A-1\n';
  static const _PUSH_D ='@SP\n' 'A=M-1\n' 'M=D\n';

  //generates the assembly code for jumping to either
  // the IF_TRUE or IF_FALSE label based on the result of the comparison
  static _jump_gt() => '@IF_TRUE${_counter_TRUE}\n'
      'D;JGT\n'
      'D=0\n'
      '@IF_FALSE${_counter_FALSE}\n'
      '0;JMP\n'
      '(IF_TRUE${_counter_TRUE})\n'
      'D=-1\n'
      '(IF_FALSE${_counter_FALSE})\n'; //


  static var _counter_TRUE = 0;
  static var _counter_FALSE = 0;

  final _rout_map = {'eq': _eq, 'gt': _gt, 'lt': _lt, 'gta': _gta};

  //compares the top two values on the stack and pushes -1 if they are equal and 0 otherwise
  static _eq() =>
      _PREFIX_BINARY_OPERATOR +
      'D=D-M\n'
      '@IF_TRUE${_counter_TRUE}\n'
      'D;JEQ\n'
      'D=1\n'
      '(IF_TRUE${_counter_TRUE})\n'
      'D=D-1\n' +
      _PUSH_D;

  //compare the top two values on the stack and push -1 if the second value is greater than the first
  static _gt() => _PREFIX_BINARY_OPERATOR + 'D=M-D\n' + _jump_gt() + _PUSH_D;
  static _gta() => _PREFIX_BINARY_OPERATOR + 'D=D-M\n' + _jump_gt() + _PUSH_D;
  //compare the top two values on the stack and push -1 if the second value is smaller than the forst.
  static _lt() => _PREFIX_BINARY_OPERATOR + 'D=D-M\n' + _jump_gt() + _PUSH_D;

  parse(line)
   {
    _counter_FALSE++;
    _counter_TRUE++;
    return _rout_map[line]!();
  }
}