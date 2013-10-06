import 'package:parse/lex.dart';
import 'package:parse/dparser.dart';

class Token {}
class Keyword extends Token {
  String keyword;
  Keyword(this.keyword);
  toString() => 'KW($keyword)';
  bool operator==(other) => keyword == other.keyword;
}
class Identifier extends Token {
  String name;
  Identifier(this.name);
  toString() => 'ID($name)';
  bool operator==(other) => name == other.name;
}
class Whitespace extends Token {
  String name;
  Whitespace(this.name);
  toString() => 'WS($name)';
}
class Semicolin extends Token {
  String name;
  Semicolin(this.name);
  toString() => 'Semicolin($name)';
  bool operator==(other) => name == other.name;
}

var _ = null;

Rule reservedWords =
  (W('assert') | W('break') | W('case') | W('catch') | W('class') | W('const')
      | W('continue') | W('default') | W('do') | W('else') | W('extends')
      | W('false') | W('final') | W('finally') | W('for') | W('if') | W('in')
      | W('is') | W('new') | W('null') | W('return') | W('super') | W('switch')
      | W('this') | W('throw') | W('true') | W('try') | W('var') | W('void')
      | W('while') | W('with')) <= (_) => new Keyword(_);

//Rule identifier = IDENTIFIER <= (_) => new Identifier(_);
//Rule whitespace = WHITESPACE <= (_) => hidden(new Whitespace(_));

Language IDENTIFIER = IDENTIFIER_START + IDENTIFIER_PART *_ ;
Language IDENTIFIER_NO_DOLLAR = IDENTIFIER_START_NO_DOLLAR
                              + IDENTIFIER_PART_NO_DOLLAR *_ ;

Language IDENTIFIER_START = IDENTIFIER_START_NO_DOLLAR | T('\$');
Language IDENTIFIER_START_NO_DOLLAR = LETTER | T('_');
Language IDENTIFIER_PART_NO_DOLLAR =  IDENTIFIER_START_NO_DOLLAR | DIGIT;
Language IDENTIFIER_PART = IDENTIFIER_START | DIGIT;
Language LETTER = (R('a')..R('z')) | (R('A')..R('Z'));
Language DIGIT = R('0')..R('9'); // end result is an instance of CharSet
Language WHITESPACE = (T('\t') | T(' ') | NEWLINE) +_ ;
Language NEWLINE = T('\n') | T('\r');
Language RESERVED_WORDS =
  (W('assert') | W('break') | W('case') | W('catch') | W('class') |W('const')
      | W('continue') | W('default') | W('do') | W('else') | W('extends')
      | W('false') | W('final') | W('finally') | W('for') | W('if') | W('in')
      | W('is') | W('new') | W('null') | W('return') | W('super') | W('switch')
      | W('this') | W('throw') | W('true') | W('try') | W('var') | W('void')
      | W('while') | W('with'));



Parser identifier = P((_) => _ is Identifier);
Parser semicolin = P((_) => _ is Semicolin);

Parser variableDeclaration = 
  declaredIdentifier + (TT(',') + identifier) *_
  ;

Parser declaredIdentifier = /*metadata +*/ finalConstVarOrType + identifier;
Parser metadata = (
    (TT('@') + qualified)
    + ( (TT('.') + IDENTIFIER ) %_ )
    + (arguments %_)) *_
  ;
Parser finalConstVarOrType =
  ( (TT(new Keyword('final')) + type)%_ )
  | ( (TT(new Keyword('const')) + type) %_ )
  | varOrType
  ;

Parser varOrType =
  TT(new Keyword('var'))
  | type
  ;

Parser type = typeName; // + typeArguments %_ ;
Parser typeName = qualified;
Parser qualified = identifier + (TT('.') + identifier) %_;

//var typeArguments = T('<') + typeList + T('>');
//var typeList = type + (T(',') + type)*_;






var arguments = T('(') + (argumentList%_) + T(')');
var argumentList = namedArgument + (T(',') + namedArgument) *_
  | expressionList + (T(',') + namedArgument) *_;

var namedArgument = label + expression;

var expressionList = expression + (T(',') + expression)*_;
var label = null; //TODO
var expression = assignableExpression + assignmentOperator + expression
  | conditionalExpression + cascadeSection*_
  | throwExpression;

var assignableExpression;
var assignmentOperator;
var conditionalExpression;
var cascadeSection;
var throwExpression;

var expressionWithoutCascade =
  assignableExpression + assignmentOperator + expressionWithoutCascade
  | conditionalExpression
  | throwExpressionWithoutCascade
  ;

var throwExpressionWithoutCascade;

var primary =
  thisExpression
  | W('super') + assignableSelector
  | functionExpression
  | literal
  | IDENTIFIER
  | newExpression
  | constObjectExpression
  | T('(') + expression + T(')')
  | argumentDefinitionTest
  ;

var argumentDefinitionTest;
var thisExpression = W('this');

var assignableSelector =
  T('[') + expression + T(']')
  | T('.') + IDENTIFIER
  ;

var functionExpression;
var literal;
var newExpression;
var constObjectExpression;


class DartLexer extends Lexer {
  void Rules(){
    this.main >> ( T(';') <= (_) => emit(new Semicolin(_.join())) )
              >> ( WHITESPACE <= (_) => hidden(new Whitespace(_.join())) )
              >> ( IDENTIFIER <= (_) => emit(new Identifier(_.join())) )
              >> ( RESERVED_WORDS <= (_) => emit(new Keyword(_.join())) )
              >> ( new END() <= (_) => terminate() );

    /*
      varOrType:
      var
      | type
      ;
    */    
  }
}

class Node {}

class Variable extends Node {
  var type = 'var';
  var name;
  var value;
  Variable(this.name, [value, type]){
    if (?type) type = 'var';
    type = type;
    value = value;
  }
  toString() => (value == null)? '$type $name;': '$type $name = $value';
}

class DartParser {
  Parser parser;
  void Rules(){
    var identifier = P((_) => _ is Identifier);
    var semicolin = P((_) => _ is Semicolin);
    var variable = TT(new Keyword('var')) + identifier + semicolin <= (_) {
      return new Variable(_.first[1].name);
    };

    parser = variable *_;
  }
}

//Parser simpleVar = W('var') + identifier + T(';'); // var me;


void main() {
  String s = 'var bla   ;\n';

  var rules = [reservedWords]; //, whitespace, identifier];
  var o = new DartLexer()..Rules()..lex(s);

  //var r = identifier.derive('v').derive('a').derive('r').derive(' ');
  //print(r.accepts);

  print(o.output);

  var p = new DartParser()..Rules();
  print(p.parser.parse(o.output));

}

/*
  1. split chars into tokens "var bla;" => W('var') Id('bla')
 */

