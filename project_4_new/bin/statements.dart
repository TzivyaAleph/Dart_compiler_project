import 'Entities.dart';
import 'expressions.dart';

class Statements {
  final List tokenList;
  Expressions? expression;

  Statements(this.tokenList) {
    expression = new Expressions(tokenList);
  }

  statements(TokenNode father) {
    // statements
    var tokenNode = TokenNode(Grammar.statements, father);
    tokenNode.sons = [];
    while (tokenList.first.value != '}') {
      tokenNode.sons!.add(_statement(tokenNode));
    }
    return tokenNode;
  }

  _statement(TokenNode father) {
    switch (tokenList.first.value) {
      case 'let':
        return _letStatement(father);
      case 'if':
        return _ifStatement(father);
      case 'while':
        return _whileStatement(father);
      case 'do':
        return _doStatement(father);
      case 'return':
        return _returnStatement(father);
    }
  }

  _letStatement(TokenNode father) {
    // letStatement
    var tokenNode = TokenNode(Grammar.letStatement, father);
    tokenNode.sons = [
      // let
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // varName
      TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0)),
    ];
    // ('[' expression ']')?
    if (tokenList.first.value == '[') {
      tokenNode.sons!.addAll([
        // [
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // expression
        expression!.expression(tokenNode),
        // ]
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
      ]);
    }
    tokenNode.sons!.addAll([
      // =
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // expression
      expression!.expression(tokenNode),
      // ;
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
    ]);
    return tokenNode;
  }

  _ifStatement(TokenNode father) {
    // ifStatement
    var tokenNode = TokenNode(Grammar.ifStatement, father);
    tokenNode.sons = [
      // if
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // (
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // expression
      expression!.expression(tokenNode),
      // )
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // {
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // statements
      statements(tokenNode),
      // }
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
    ];
    // ( 'else' '{' statements '}' )?
    if (tokenList.first.value == 'else') {
      tokenNode.sons!.addAll([
        // else
        TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
        // {
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // statements
        statements(tokenNode),
        // }
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
      ]);
    }
    return tokenNode;
  }

  _whileStatement(TokenNode father) {
    var tokenNode = TokenNode(Grammar.whileStatement, father);
    tokenNode.sons = [
      // while
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
      // (
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // expression
      expression!.expression(tokenNode),
      // )
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // {
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
      // statements
      statements(tokenNode),
      // }
      TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
    ];
    return tokenNode;
  }

  _doStatement(TokenNode father) {
    var tokenNode = TokenNode(Grammar.doStatement, father);
    tokenNode.sons = [
      // do
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0)),
    ];

    // subroutineCall
    expression!.subroutineCall(tokenNode);
    // ;
    tokenNode.sons!.add(
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)));
    return tokenNode;
  }

  _returnStatement(TokenNode father) {
    var tokenNode = TokenNode(Grammar.returnStatement, father);
    tokenNode.sons = [
      // return
      TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0))
    ];
    if (tokenList.first.value != ';') {
      tokenNode.sons!.add(expression!.expression(tokenNode));
    }
    tokenNode.sons!.add(
        // ;
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)));
    return tokenNode;
  }
}