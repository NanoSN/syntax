library parse;

import 'dart:core';

abstract class Parser {

  And operator +(Parser right){
    return new And(this, right);
  }
  And operator *(Parser right){
    if( right != null)
      throw 'right of * must be null';
    return null;
  }
  
  bool isNullable();
  bool isEmpty();
  Set  parseNull();
  Parser derive(token);
  
  List parse(List tokens){
    var parser = this;
    for( var token in tokens){
      parser = parser.derive(token);
    }
    return parser.parseNull();
  }
}

class Empty extends Parser {
  bool isNullable() => false;
  bool isEmpty() => true;
  Set parseNull() => new Set();
  Parser derive(token) => new Empty();

  /** singleton factory */
  static final _instance = new Empty._internal();
  factory Empty() => _instance;
  Empty._internal();
}

class Null extends Parser {

  Set result;
  
  bool isNullable() => true;
  bool isEmpty() => false;
  Set parseNull() => this.result;
  Parser derive(token) => new Empty();

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
      this.resutt.add(null);
    }
  }
}

class Token extends Parser {
  var token;
  Token(this.token);

  bool isNullable() => false;
  bool isEmpty() => false;
  Set parseNull() => new Set();
  Parser derive(token){
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
  Set parseNull() => new Set();
  Parser derive(token){
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
  Set parseNull(){
    Set result = new Set();
    for ( var l in this.first.parseNull()) {
      for (var r in this.second.parseNull())
        result.add([l,r]);
    }
    return result;
  }
  
  Parser derive(token){
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

  Set parseNull(){
    Set result = new Set();
    result.addAll(this.first.parseNull());
    result.addAll(this.second.parseNull());
    return result;
  }
  
  Parser derive(token){
    if (this.first.isEmpty()){
      return this.second.derive(token);
    }
    if (this.second.isEmpty()){
      return this.first.derive(token);
    }
    return new Or(this.first.derive(token), this.second.derive(token));
  }
}

