part of parser;

/// TODO: move out Ast
class AstNode {
  final int hashCode;
  static int _HASH_COUNTER = 0;
  static int _TO_STRING_INDENTATION = 0;

  AstNode() : hashCode = ++_HASH_COUNTER;

  AstNode parent;
  final List<AstNode> children = <AstNode>[];
  final List<Token> tokens = <Token>[];
  toString(){
    var indent = ++_TO_STRING_INDENTATION;
    var sb = new StringBuffer();
    sb.writeln('$runtimeType:');
    for(var i=0; i<indent; i++) sb.write('  ');
    sb.writeln('`- tokens:');

    for(final token in tokens){
      for(var i=0; i<=indent; i++) sb.write('  ');
      sb.write('`- ');
      sb.writeln(token);
    }

    for(var i=0; i<indent; i++) sb.write('  ');
    sb.writeln('`- children:');
    for(final child in children){
      for(var i=0; i<=indent; i++) sb.write('  ');
      sb.write('');
      sb.write(child);
    }
    sb.writeln();
    return sb.toString();
  }

}

Parser reject = new Reject();
Parser match = new Match();

abstract class Parser extends Inspector {
  final Map<Token, Parser> derivatives = new Map<Token, Parser>();
  bool get isMatchable => false;
  Parser derive(Token t) =>
      derivatives.putIfAbsent(t, () => _derive(t));
  Parser _derive(Token t);
  toAst() => [];//throw "$runtimeType.toAst(): can't be called from here.";
  Reducer operator <=(Function fn) => makeReduce(this, fn);
}


/// A [Parser] that rejects everything.
class Reject extends Parser {
  Parser _derive(Token t) => reject;
  toString() => '{}';
}

/// A [Parser] that matches the defined [Parser].
class Match extends Parser {
  bool get isMatchable => true;
  Parser _derive(Token t) => reject;
  toString() => "{''}";
}

/// A [Parser] that matches the defined [Parser].
class AstNodeMatch extends Match {
  List<AstNode> ast;
  AstNodeMatch([this.ast]);
  toAst() => ast;
}

class Lazy extends Parser {
  final Parser parser;
  final String name;
  Lazy(this.parser, this.name);
  bool get isMatchable {

    if(parser == null) {
//          print(cache);
          throw "Whaat $name";
        }
    return parser.isMatchable;
  }
  Parser _derive(Token t) => parser.derive(t);
  toAst() {
    if(parser == null) {
      // TODO: How is this happening and why? need RCA.
      return [];
    }
    return parser.toAst();
  }
  toString() => 'Lazy($name)';
}

/// A [Parser] that matches a specific [Token].
class TokenParser extends Parser {
  final TokenDefinition tokenDef;
  TokenParser(this.tokenDef);
  Parser _derive(Token t) {
    if(tokenDef == t){
      return new AstNodeMatch([_createNode(t)]);
    } else {
      return reject;
    }
  }
  toString() => 'TokenParser($tokenDef)';
  _createNode(Token t) => new AstNode()..tokens.add(t);
}

/// A [Parser] that matches either of two [Parser]s.
class Or extends Parser {
  final Parser left;
  final Parser right;

  bool get isMatchable => left.isMatchable || right.isMatchable;

  Or._internal(this.left, this.right);
  factory Or(left, right) => throw "Not permitted. Use makeOr instead";
  Parser _derive (Token t) {
    return makeOr(left.derive(t), right.derive(t));
  }
  toString() => '$left|$right';
  toAst() {
    var leftAst = left.toAst();
    var rightAst = right.toAst();
    var ast = [];
    for(final l in leftAst){
      for(final r in rightAst){
        ast.addAll([l,r]);
      }
    }
    return ast;
  }
}

/// A [Parser] that matches two [Parser]s in sequence.
class And extends Parser {
  final Parser left;
  final Parser right;

  bool get isMatchable => left.isMatchable && right.isMatchable;

  And._internal(this.left, this.right);
  factory And(left, right) => throw "Not permitted. Use makeAnd instead";

  Parser _derive (Token t) {
    if(left.isMatchable){
      return makeOr(makeAnd(left.derive(t), right),
                    makeAnd(new AstNodeMatch(left.toAst()), right.derive(t)));
    }
    return makeAnd(left.derive(t), right);
  }
  toString() => "$left$right";
  toAst() {
    var leftAst, rightAst = [];
   leftAst = left.toAst();
   rightAst = right.toAst();
    var ast = [];
    ast.addAll(leftAst);
    ast.addAll(rightAst);
    return ast;
  }
}

/// A [Parser] that matches the kleene star of a [Parser].
class Star extends Parser {
  final Parser parser;

  bool get isMatchable => true; //fixMatchable();

  Star._internal(this.parser);
  factory Star(parser) => throw "Not permitted. Use makeStar instead";

  Parser _derive(Token t) => makeAnd(parser.derive(t), makeStar(parser));
  toString() => '$parser*';

  bool _isMatchable = null;
  bool fixMatchable(){
    if(_isMatchable != null) return _isMatchable;
    bool value = null;
    while(true) {
      value = parser.isMatchable;
      if(_isMatchable == value)
        break;
      _isMatchable = value;
    }
    return _isMatchable;
  }
  toAst() => parser.toAst();
}

typedef AstNode AstCreator(List<AstNode> nodes);

/// A [Parser] that reduces the matched tokens to an Ast node.
class Reduce extends Parser {
  final Parser parser;
  final AstCreator astCreator;
  bool get isMatchable => parser.isMatchable;

  Reduce._internal(this.parser, this.astCreator);
  factory Reduce(parser, astCreator) =>
      throw "Not permitted. Use makeReduce instead";

  Parser _derive(Token t) => makeReduce(parser.derive(t), astCreator);
  toString() => 'reduce($parser)';
  toAst(){
    List<AstNode> result = <AstNode>[];
    List<AstNode> nodes = parser.toAst();
    result.add(astCreator(nodes));
    return result;
  }
}

/// A [Parser] that matches zero or one of a [Parser].
class Optional extends Parser {
  final Parser parser;

  bool get isMatchable => true;

  Optional._internal(this.parser);
  factory Optional(parser) => throw "Not permitted. Use makeOptional instead";

  Parser _derive(ch) => parser.derive(ch);
  toString() => '($parser)?';
  toAst() => parser.toAst();
}


/// Helper factory functions.
/// (sam): moved them out of factory constructors because checked mode
/// complained that they don't return the same type.
Parser makeOr(Parser left, Parser right){
  if (left == reject && right == reject) return reject;
  if (left == reject) return right;
  if (right == reject) return left;
  if (left is Match && right is Match) //Ambiguity .. return forest for debugging
    return new AstNodeMatch([left.toAst(), right.toAst()]);
  if (left is Match) return new AstNodeMatch(left.toAst());
  if (right is Match) return new AstNodeMatch(right.toAst());
  return new Or._internal(left, right);
}

Parser makeAnd(Parser left, Parser right){
  if(left == reject || right == reject) return reject;
  if(left is Match && right is Match)
    return new AstNodeMatch(new And._internal(left, right).toAst());
  return new And._internal(left, right);
}

Parser makeStar(Parser parser){
  if(parser is  Match) return new AstNodeMatch(parser.toAst());
  if(parser == reject) return reject;
  return new Star._internal(parser);
}

Parser makeReduce(Parser parser, AstCreator astCreator){
  if(parser == reject) return reject;
  if(parser is Match) return new AstNodeMatch([astCreator(parser.toAst())]);

  return new Reduce._internal(parser, astCreator);
}

Parser makeOptional(Parser parser){
  if(parser is Match) return new AstNodeMatch(parser.toAst());
  if(parser == reject) return reject;
  return new Optional._internal(parser);
}
