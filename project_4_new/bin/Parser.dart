import 'dart:io';

import 'Entities.dart';
import 'expressions.dart';
import 'program-structure.dart';
import 'statements.dart';
import 'package:xml/xml.dart';

class Parser {
  final List<Token> tokenList;
  late ProgramStructure _programStructure;
  late Statements _statements;
  late Expressions _expressions;
  late TokenNode root;

  Parser(this.tokenList) {
    _programStructure = new ProgramStructure(tokenList);
    _statements = new Statements(tokenList);
    _expressions = new Expressions(tokenList);
  }

  parse() {
    // root
    TokenNode? t = null;
    root = TokenNode(Grammar.$class, t);
    _programStructure.$class(root);
  }

  getXmlTextNode(TokenNode? t, r) {
    if (t == null) return '';
    var grammar =
        t.grammar.toString().substring(t.grammar.toString().indexOf('.') + 1);
    if (grammar == r'$class') grammar = 'class';

    var xmlText = '';

    if (t.token != null) {
      xmlText += '$r<$grammar> ${t.token!.value} </$grammar>';
    } else if (t.sons != null) {
      xmlText += '$r<$grammar>\n';
      for (var node in t.sons ?? []) {
        xmlText += getXmlTextNode(node, r + '  ')+'\n';
      }
      xmlText += '$r</$grammar>';
    } else {
      xmlText += '$r<$grammar>\n$r</$grammar>';
    }
    return xmlText;
  }

  exportToXml(String jackFileName, {TokenNode? tokenRootNode = null}) {
    if (tokenRootNode == null) {
      tokenRootNode = root;
    }
    var xmlObject = getXml(tokenRootNode);
    var xmlText = getXmlTextNode(tokenRootNode, '');

    var xmlFile = File(jackFileName+'.xml');
    // xmlFile.writeAsString(xmlObject.toXmlString(pretty: true));
    xmlFile.writeAsString(xmlText);
  }

  XmlElement? getXml(TokenNode tokenNode) {
    if (tokenNode == null) return null;
    var grammar = tokenNode.grammar
        .toString()
        .substring(tokenNode.grammar.toString().indexOf('.') + 1);
    if (grammar == r'$class') grammar = 'class';

    if (tokenNode.token != null) {
      return XmlElement(XmlName(grammar),
        [],
        [ XmlText(tokenNode.token!.value) ]
      );
    } else if (tokenNode.sons != null) {
      var element = XmlElement(XmlName(grammar));
      for (var node in tokenNode.sons ?? []) {
        element.children.add(getXml(node) as XmlNode);
      }
      return element;
    } else {
      return XmlElement(XmlName(grammar));
    }
  }
}