part of parser;

Parser reject = new Reject();
Parser match = new Match();

abstract class Parser extends Inspector {
  final Map<Token, Parser> derivatives = <Token, Parser>{};
  final String name;
  Parser(this.name);
  bool get isMatchable => false;
  Parser derive(Token t) =>
      derivatives.putIfAbsent(t, () => _derive(t));
  Parser _derive(Token t);
  toAst() => new AstList();
  Parser operator <=(Function fn) => makeReduce(this, fn);
  bool fixMatchable(Parser p){
    bool value, result = false;
    while(true) {
      value = p.isMatchable;
      if(result == value)
        break;
      result = value;
    }
    return result;
  }
  toDot();
  toReadableString() {
    if(name != null) return name;
    return '';
  }
}


/// A [Parser] that rejects everything.
class Reject extends Parser {
  Reject([name]): super(name);
  Parser _derive(Token t) => reject;
  toDot() => 'Reject;';
  toString() => '{}';
}

/// A [Parser] that matches the defined [Parser].
class Match extends Parser {
  Match([name]): super(name);
  bool get isMatchable => true;
  Parser _derive(Token t) => reject;
  toDot() => 'Match;';
  toString() => "{''}";
}

/// A [Parser] that matches the defined [Parser].
class AstNodeMatch extends Match {
  AstList ast;
  AstNodeMatch([this.ast, name]): super(name);
  toDot() => 'AstNodeMatch;';
  toAst() => ast;
}

class Lazy extends Parser {
  Parser _parser;
  Parser get parser {
    if( _parser == null) {
      _parser = cache[name];
    }
    return _parser;
  }
  Lazy(this._parser, name): super(name);
  bool _isMatchable = null;
  bool get isMatchable => parser.isMatchable;
  // {
  //   if(_isMatchable != null) return _isMatchable;
  //   _isMatchable = fixMatchable(parser);
  //   return _isMatchable;
  // }

  Parser _derive(Token t) {
    return parser.derive(t);
  }
  bool called = false;
  var val = [];
  toAst() {
    if(called) return val;
    called = true;
    var value, result = null;
    while(true) {
      value = parser.toAst();
      if(result == value)
        break;
      result = value;
    }
    val = result;
    return val;
  }
  toDot() => 'Lazy($name);';
  toString() => 'Lazy($name)';
  toReadableString() => name;
}

/// A [Parser] that matches a specific [Token].
class TokenParser extends Parser {
  final TokenDefinition tokenDef;
  TokenParser(this.tokenDef, [name]): super(name);
  Parser _derive(Token t) {
    if(tokenDef == t){
      return new AstNodeMatch(new AstList()..add(_createNode(t)));
    } else {
      return reject;
    }
  }
  toDot() => '$this;';
  toString() => 'TokenParser($tokenDef)';
  _createNode(Token t) => new AstNode()..tokens.add(t);
}

/// A [Parser] that matches either of two [Parser]s.
class Or extends Parser {
  final Parser left;
  final Parser right;

  bool get isMatchable => left.isMatchable && right.isMatchable;

  Or._internal(this.left, this.right, [name]): super(name);
  factory Or(left, right) => throw "Not permitted. Use makeOr instead";
  Parser _derive (Token t) {
    return makeOr(left.derive(t), right.derive(t));
  }
  toDot() => 'Or -> ${left.toDot()}\n'
             'Or -> ${right.toDot()}\n';
  toString() => '$left|$right';
  toAst() {
    var leftAst = left.toAst();
    var rightAst = right.toAst();
    var ast = new AstList();
    for(final l in leftAst){
      for(final r in rightAst){
        ast.addAll([l,r]);
      }
    }
    return ast;
  }
  toReadableString() {
    StringBuffer sb = new StringBuffer();
    if(left.name != null) sb.write(left.name);
    if(right.name != null) sb.write(right.name);
    return sb.toString();
  }
}

/// A [Parser] that matches two [Parser]s in sequence.
class And extends Parser {
  final Parser left;
  final Parser right;

  bool get isMatchable => left.isMatchable && right.isMatchable;

  And._internal(this.left, this.right, [name]): super(name);
  factory And(left, right) => throw "Not permitted. Use makeAnd instead";

  Parser _derive (Token t) {
    if(left.isMatchable){
      return makeOr(makeAnd(left.derive(t), right),
                    makeAnd(new AstNodeMatch(left.toAst()), right.derive(t)));
    }
    return makeAnd(left.derive(t), right);
  }
  toDot() => 'And -> ${left.toDot()}\n'
             'And -> ${right.toDot()}\n';
  toString() => "$left$right";
  toAst() {
    var leftAst, rightAst;
    leftAst = left.toAst();
    rightAst = right.toAst();
    var ast = new AstList();
    ast.addAll(leftAst);
    ast.addAll(rightAst);
    return ast;
  }
  toReadableString() {
    StringBuffer sb = new StringBuffer();
    if(left.name != null) sb.write(left.name);
    if(right.name != null) sb.write(right.name);
    return sb.toString();
  }
}

/// A [Parser] that matches the kleene star of a [Parser].
class Star extends Parser {
  final Parser parser;

  bool get isMatchable => true; //fixMatchable();

  Star._internal(this.parser, [name]): super(name);
  factory Star(parser) => throw "Not permitted. Use makeStar instead";

  Parser _derive(Token t) => makeAnd(parser.derive(t), makeStar(parser));
  toString() => '$parser*';
  toDot() => parser.toDot();
  toAst() => parser.toAst();
  toReadableString() {
    if(parser.name != null) return parser.name;
    return '';
  }
}

typedef AstNode AstCreator(AstList nodes);

/// A [Parser] that reduces the matched tokens to an Ast node.
class Reduce extends Parser {
  final Parser parser;
  final AstCreator astCreator;
  bool get isMatchable => parser.isMatchable;

  Reduce._internal(this.parser, this.astCreator, [name]): super(name);
  factory Reduce(parser, astCreator) =>
      throw "Not permitted. Use makeReduce instead";

  Parser _derive(Token t) => makeReduce(parser.derive(t), astCreator);
  toString() => 'reduce($parser)';
  toDot() => 'Reduce -> ${parser.toDot()}';
  toAst(){
    AstList result = new AstList();
    AstList nodes = parser.toAst();
    result.add(astCreator(nodes));
    return result;
  }
  toReadableString() {
    if(parser.name != null) return parser.name;
    return '';
  }
}

/// A [Parser] that matches zero or one of a [Parser].
class Optional extends Parser {
  final Parser parser;

  bool get isMatchable => true;

  Optional._internal(this.parser, [name]): super(name);
  factory Optional(parser) => throw "Not permitted. Use makeOptional instead";

  Parser _derive(ch) => parser.derive(ch);
  toDot() => 'Reduce -> ${parser.toDot()}';
  toString() => '($parser)?';
  toAst() => parser.toAst();
  toReadableString() {
    if(parser.name != null) return parser.name;
    return '';
  }
}


/// Helper factory functions.
/// (sam): moved them out of factory constructors because checked mode
/// complained that they don't return the same type.
Parser makeOr(Parser left, Parser right, [name]){
  if (left == reject && right == reject) return reject;
  if (left == reject) return right;
  if (right == reject) return left;
  if (left is Match && right is Match) //Ambiguity .. return forest for debugging
    return new AstNodeMatch(new AstList()..addAll([left.toAst(),
                                                   right.toAst()]), name);
  if (left is Match) return new AstNodeMatch(left.toAst(), name);
  if (right is Match) return new AstNodeMatch(right.toAst(), name);
  return new Or._internal(left, right, name);
}

Parser makeAnd(Parser left, Parser right, [name]){
  if(left == reject || right == reject) return reject;
  if(left is Match && right is Match)
    return new AstNodeMatch(new And._internal(left, right).toAst(), name);
  // if(left is Match) return right;
  // if(right is Match) return left;
  return new And._internal(left, right, name);
}

Parser makeStar(Parser parser, [name]){
  if(parser is  Match) return new AstNodeMatch(parser.toAst(), name);
  if(parser == reject) return reject;
  return new Star._internal(parser, name);
}

Parser makeReduce(Parser parser, AstCreator astCreator, [name]){
  if(parser == reject) return reject;
  if(parser is Match) return new AstNodeMatch(new AstList()
    ..addAll([astCreator(parser.toAst())]), name);

  return new Reduce._internal(parser, astCreator, name);
}

Parser makeOptional(Parser parser, [name]){
  if(parser is Match) return new AstNodeMatch(parser.toAst(), name);
  if(parser == reject) return reject;
  return new Optional._internal(parser, name);
}
