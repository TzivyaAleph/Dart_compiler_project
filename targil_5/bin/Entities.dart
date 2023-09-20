enum TokenType { keyword, symbol, integerConstant, stringConstant, identifier }
enum Grammar {
  keyword,
  symbol,
  integerConstant,
  stringConstant,
  identifier,
  $class,
  classVarDec,
  type,
  subroutineDec,
  parameterList,
  subroutineBody,
  varDec,
  statements,
  statement,
  letStatement,
  ifStatement,
  whileStatement,
  doStatement,
  returnStatement,
  expression,
  term,
  subroutineCall,
  expressionList
}

String getTokenString(TokenType type) {
  return type.toString().substring(type.toString().indexOf('.') + 1);
}

class Token {
  final TokenType type;
  final String value;

  Token(this.type, this.value );
}

class TokenNode {
  Token? token;
  Grammar grammar;
  TokenNode? father;
  List<TokenNode>? sons = null;

  TokenNode(this.grammar, this.father, {this.token = null});
  @override
  String toString() {
    var t = token!=null?token!.value: '';
    return grammar.toString() + '\t' + t;
  }
}