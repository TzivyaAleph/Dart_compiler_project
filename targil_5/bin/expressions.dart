import 'Entities.dart';

class Expressions {
  final List tokenList;

  Expressions(this.tokenList);

  expression(TokenNode father) {
    var tokenNode = TokenNode(Grammar.expression, father);
    tokenNode.sons = [
      // term
      _term(tokenNode)
    ];
    while (['+', '-', '*', '/', '|', '&amp;', '&lt;', '&gt;', '=']
      .contains(tokenList.first.value)) {
      tokenNode.sons!.addAll([
        // op
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // term
        _term(tokenNode)
      ]);
    }
    return tokenNode;
  }

  _term(TokenNode father) {
    var tokenNode = TokenNode(Grammar.term, father);
    if (tokenList.first.type == TokenType.integerConstant) {
      tokenNode.sons = [
        TokenNode(Grammar.integerConstant, tokenNode,
          token: tokenList.removeAt(0))
      ];
    } else if (tokenList.first.type == TokenType.stringConstant) {
      tokenNode.sons = [
        TokenNode(Grammar.stringConstant, tokenNode,
          token: tokenList.removeAt(0))
      ];
    } else if (['true', 'false', 'null', 'this']
      .contains(tokenList.first.value)) {
      tokenNode.sons = [
        TokenNode(Grammar.keyword, tokenNode, token: tokenList.removeAt(0))
      ];
    } else if (['-', '~'].contains(tokenList.first.value)) {
      tokenNode.sons = [
        // unaryOp
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // term
        _term(tokenNode)
      ];
    } else if (tokenList.first.value == '(') {
      tokenNode.sons = [
        // (
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
        // expression
        expression(tokenNode),
        // )
        TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
      ];
    } else if (tokenList.first.type == TokenType.identifier) {
      if (tokenList[1].value == '(' || tokenList[1].value == '.') {
        subroutineCall(tokenNode);
      } else {
        tokenNode.sons = [
          // varName
          TokenNode(Grammar.identifier, tokenNode, token: tokenList.removeAt(0))
        ];
        if (tokenList.first.value == '[') {
          tokenNode.sons!.addAll([
            // [
            TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
            // expression
            expression(tokenNode),
            // ]
            TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0))
          ]);
        }
      }
    }
    return tokenNode;
  }

  // creates the function we call from doStatements
  subroutineCall(TokenNode father) {
    if(father.sons == null){
      father.sons = [];
    }
    // var tokenNode = TokenNode(Grammar.subroutineCall, father);
    father.sons!.add(
      // subroutineName | className | varName
      TokenNode(Grammar.identifier, father, token: tokenList.removeAt(0))
    );
    if (tokenList.first.value == '.') {
      father.sons!.addAll([
        // .
        TokenNode(Grammar.symbol, father, token: tokenList.removeAt(0)),
        // subroutineName
        TokenNode(Grammar.identifier, father, token: tokenList.removeAt(0))
      ]);
    }
    father.sons!.addAll([
      // (
      TokenNode(Grammar.symbol, father, token: tokenList.removeAt(0)),
      // expressionList
      _expressionList(father),
      // )
      TokenNode(Grammar.symbol, father, token: tokenList.removeAt(0))
    ]);
    //return father;
  }

  _expressionList(TokenNode father) {
    var tokenNode = TokenNode(Grammar.expressionList, father);
    if (tokenList.first.value != ')') {
      tokenNode.sons = [
        // expression
        expression(tokenNode)
      ];
      while (tokenList.first.value == ',') {
        tokenNode.sons!.addAll([
          // ,
          TokenNode(Grammar.symbol, tokenNode, token: tokenList.removeAt(0)),
          // expression
          expression(tokenNode)
        ]);
      }
    }
    return tokenNode;
  }
}