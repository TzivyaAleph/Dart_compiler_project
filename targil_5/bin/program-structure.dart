import 'Entities.dart';
import 'statements.dart';

class ProgramStructure {
  final List tokenList;
  Statements? statements;

  ProgramStructure(this.tokenList){
    statements = new Statements(tokenList);
  }

  void $class(TokenNode root) {
    root.sons = [
      // class
      TokenNode(Grammar.keyword, root, token: tokenList.removeAt(0)),
      // className
      TokenNode(Grammar.identifier, root, token: tokenList.removeAt(0)),
      // {
      TokenNode(Grammar.symbol, root, token: tokenList.removeAt(0)),
    ];
    // classVarDec*
    while (tokenList[0].value == 'static' || tokenList[0].value == 'field') {
      root.sons!.add(_classVerDec(root));
    }
    // subroutineDec*
    while (
        ['constructor', 'function', 'method'].contains(tokenList.first.value)) {
      root.sons!.add(_subroutineDec(root));
    }
    // }
    root.sons!
        .add(TokenNode(Grammar.symbol, root, token: tokenList.removeAt(0)));
  }

  ///creates the grammer : classVarDec (static | field) type varName(',' varName)*
  TokenNode _classVerDec(TokenNode father) {
    // classVarDec
    var tokenNode = TokenNode(Grammar.classVarDec, father);
    tokenNode.sons = [
      // static | field
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // type
      _type(tokenNode),
      // varName
      TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0)),
    ];
    //  (',' varName)*
    while (tokenList[0].value == ',') {
      tokenNode.sons!.addAll([
        // ,
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // varName
        TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
      ]);
    }
    // ;
    tokenNode.sons!.add(
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)));
    return tokenNode;
  }
/// searches for the type and return a tokenNode with that type
  _type(TokenNode father) {
    var grammar = Grammar.values.firstWhere((g) =>
        g.toString().substring(g.toString().indexOf('.') + 1) ==
        tokenList[0]
            .type
            .toString()
            .substring(tokenList[0].type.toString().indexOf('.') + 1));
    // take type from the token
    return TokenNode(grammar, father, token: tokenList.removeAt(0));
  }

  ///builds a function 
  _subroutineDec(TokenNode father) {
    // subroutineDec
    var tokenNode = TokenNode(Grammar.subroutineDec, father);
    tokenNode.sons = [
      // ('constructor' | 'function' | 'method')
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // ('void' | type)
      _type(tokenNode),
      // subroutineName
      TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0)),
      // (
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // parameterList
      _parameterList(tokenNode),
      // )
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // subroutineBody
      _subroutineBody(tokenNode)
    ];
    return tokenNode;
  }

  _parameterList(TokenNode father) {
    // parameterList
    TokenNode tokenNode = TokenNode(Grammar.parameterList, father);
    // ( (type varName) (',' type varName)*) ?
    if (tokenList.first.value == ')') return tokenNode; //no parameters
    tokenNode.sons = [
      // type
      _type(tokenNode),
      // varName
      TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
    ];
    // (',' type varName)*
    while (tokenList.first.value == ',') {
      tokenNode.sons!.addAll([
        // ,
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // type
        _type(tokenNode),
        // varName
        TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
      ]);
    }
    return tokenNode;
  }

  _subroutineBody(TokenNode father) {
    // subroutineBody
    TokenNode tokenNode = TokenNode(Grammar.subroutineBody, father);
    tokenNode.sons = [
      // {
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
    ];
    // varDec*
    while (tokenList.first.value == 'var') {
      tokenNode.sons!.add(_varDec(tokenNode));
    }
    tokenNode.sons!.addAll([
      // statements
      statements!.statements(tokenNode),
      // }
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
    ]);
    return tokenNode;
  }

  _varDec(TokenNode father) {
    // varDec
    TokenNode tokenNode = TokenNode(Grammar.varDec, father);
    tokenNode.sons = [
      // var
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // type
      _type(tokenNode),
      // varName
      TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
    ];
    while (tokenList.first.value == ',') {
      tokenNode.sons!.addAll([
        // ,
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // varName
        TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
      ]);
    }
    // ;
    tokenNode.sons!.add(
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)));
    return tokenNode;
  }
}