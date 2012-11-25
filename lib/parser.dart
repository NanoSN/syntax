library parse;

import 'dart:core';

/** Utility function for sets equality */
bool set_equals(Set left, Set right){
  if(left == null || right == null)
    return false;
 
  //simplest case
  if(left.length != right.length)
    return false;

  //clone one of the sets
  var test = new Set.from(left);
  for(var value in right){
    if(test.contains(value))
      test.remove(value);
    else
      return false;
  }
  return test.isEmpty;
}

abstract class Parser {

  And operator +(Parser right){
    return new And(this, right);
  }
  
  Or operator |(Parser right){
    return new Or(this, right);
  }
  
  And operator *(Parser right){
    if( right != null)
      throw 'right of * must be null';
    return null;
  }

  static final _cache = {};
  Set _set;
  bool isNullable();
  bool isEmpty();
  Parser _derive(token);
  Set  _parseNull();
  Set  parseNull(){
    if(this._set != null)
      return this._set;

    Set anotherSet = new Set();
    do {
      this._set = anotherSet;
      anotherSet = this._parseNull();
    } while(!set_equals(this._set, anotherSet));
  }
  
  Parser derive(token){
    if(_cache[token] == null)
      _cache[token] = new Lazy(this, token);
    return _cache[token];
  }
  
  Set parse(List tokens){
    var parser = this;
    for( var token in tokens){
      parser = parser.derive(token);
    }
    return parser.parseNull();
  }
}

class Lazy extends Parser {
  Parser parser;
  var token;
  Parser derivative;

  Lazy(this.parser, this.token);
  Parser _derive(token){
    print('derive lazy $token');
    this._evaluate();
    return this.derivative.derive(token);
  }

  Set _parseNull(){
    print('derive lazy $token');
    this._evaluate();
    return this.derivative.parseNull();
  }
  
  void _evaluate(){
    if(this.derivative == null)
      this.derivative = this.parser._derive(this.token);
  }
}

class Empty extends Parser {
  bool isNullable() => false;
  bool isEmpty() => true;
  Set _parseNull() => new Set();
  Parser _derive(token) {
    print('derive empty');
    return new Empty();
  }

  /** singleton factory */
  static final _instance = new Empty._internal();
  factory Empty() => _instance;
  Empty._internal();
}

class Null extends Parser {

  Set result;
  
  bool isNullable() => true;
  bool isEmpty() => false;
  Set _parseNull() => this.result;
  Parser _derive(token) => new Empty();

  /** singleton factory */
  static Null _instance;
  factory Null([Set result]) {
    if(!?result && _instance != null)
      return _instance;

    _instance = new Null._internal(result);
    return _instance;
  }
  
  /** Default constructor */
  Null._internal([Set result]){
    if (?result){
      this.result = result;
    } else {
      this.result = new Set();
      this.result.add(null);
    }
  }
}

class Token extends Parser {
  var token;
  Token(this.token);

  bool isNullable() => false;
  bool isEmpty() => false;
  Set _parseNull() => new Set();
  Parser _derive(token){
    print('Token derive $token');
    if (this.token == token){
      var s = new Set();
      s.add(token);
      return new Null(s);
    }
    return new Empty();
  }
}

class RegEx extends Parser {
  String pattern;
  RegEx(this.pattern);

  bool isNullable() => false;
  bool isEmpty() => false;
  Set _parseNull() => new Set();
  Parser _derive(token){
    RegExp exp = new RegExp(this.pattern);
    if (exp.hasMatch(token)){
      var s = new Set();
      s.add(token);
      return new Null(s);
    }
    return new Empty();
  }
}

class And extends Parser {
  Parser first;
  Parser second;
  And(this.first, this.second);

  bool isNullable() => this.first.isNullable() && this.second.isNullable();
  bool isEmpty() => this.first.isNullable() || this.second.isNullable();
  Set _parseNull(){
    Set result = new Set();
    for ( var l in this.first.parseNull()) {
      for (var r in this.second.parseNull())
        result.add([l,r]);
    }
    return result;
  }
  
  Parser _derive(token){
    print('And derive $token');
    if (this.first.isNullable()){
      var left = new And(this.first.derive(token), this.second);
      var right = new And(new Null(this.first.parseNull()),
          this.second.derive(token));
      return new Or(left, right);
    }

    return new And(this.first.derive(token), this.second);
  }
}


class Or extends Parser {
  Parser first;
  Parser second;
  Or(this.first, this.second);

  bool isNullable() => this.first.isNullable() || this.second.isNullable();
  bool isEmpty() => this.first.isNullable() && this.second.isNullable();

  Set _parseNull(){
    Set result = new Set();
    result.addAll(this.first.parseNull());
    result.addAll(this.second.parseNull());
    return result;
  }
  
  Parser _derive(token){
    if (this.first.isEmpty()){
      return this.second.derive(token);
    }
    if (this.second.isEmpty()){
      return this.first.derive(token);
    }
    return new Or(this.first.derive(token), this.second.derive(token));
  }
}

class KleeneStar extends Parser {
  Parser parser;
  KleeneStar(this.parser);
  Set _parseNull() => this.parser.parseNull();
  Parser _derive(token) => this.parser.derive();
}
