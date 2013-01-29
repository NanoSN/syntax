library mine;

import 'dart:collection';
import 'package:logging/logging.dart';

var log = new Logger('parse');
var dlog = new Logger('derive');
var nlog = new Logger('parseNull');

class MySet<E> extends HashSet {
  MySet(): super();
  factory MySet.from(Iterable other) {
    MySet set = new MySet();
    for (final e in other) {
      set.add(e);
    }
    return set;
  }

  operator ==(Set other) {
    var o = new MySet.from(other);
    Set intersection = this.intersection(o);
    return intersection.length == this.length
      && intersection.length == other.length;
  }

  get hashCode {
    int hc = 0;
    for (final e in this) {
      hc << e.hashCode;
    }
    return hc;
  }
}

abstract class _Parser {
  bool get nullable;
  bool get empty;
  Parser derive(token);
  MySet parseNull();
}

abstract class Parser extends _Parser {
  And operator +(Parser other) => new And(this, other);
  Or operator |(Parser other) => new Or(this, other);
  Parser operator *(Parser other) {
    //T('b') + f | new Null();
    var star = new KleeneStar();
    star.parser = this + star | new Null();
    return star;
  }
  Reduce operator <=(Function reduction) => new Reduce(this, reduction);

  MySet parse(List tokens){
    var parser = this;
    for( var token in tokens){
      print('logging');
      print('$parser');
      print('don log');
      parser = parser.derive(token);
    }
    print('done: $parser');
    return parser.parseNull();
  }
}

class Empty extends Parser {
  bool get nullable => false;
  bool get empty => true;

  MySet parseNull() {
    var r = new MySet();
    print('$this: $r');
    return r;
  }
  Parser derive(token) {
    var r = new Empty();
    return r;
    print('($token) => $this: $r');
  }

  /// singleton factory
  static final _instance = new Empty._internal();
  factory Empty() => _instance;
  Empty._internal();
  //toString() => 'Empty';
}

class Null extends Parser {
  MySet result = new MySet.from(['']);
  bool get nullable => true;
  bool get empty => false;
  // toString() => 'Null($result)';

  MySet parseNull() {
    var r = this.result;
    print('$this: $r');
    return r;
  }

  Parser derive(token) {
    var r = new Empty();
    print('($token) => $this: $r');
    return r;
  }

  /// singleton factory
  static Null _instance;
  factory Null([MySet result]) {
    if (?result) return new Null._internal(result);
    if(_instance != null)
      return _instance;
    _instance = new Null._internal(result);
    return _instance;
  }

  /// Default constructor
  Null._internal([MySet result]){
    if (result != null){
      this.result = new MySet.from(result);
    }
  }
}

class Token extends Parser {
  var token;
  Token(this.token);

  bool get nullable => false;
  bool get empty => false;

  // toString() => 'Token($token)';

  MySet parseNull() {
    var r = new MySet();
    print('$this: $r');
    return r;
  }
  Parser derive(token){
    var r = new Empty();
    if (this.token == token){
      r = new Null(new MySet.from([token]));
    }
    print('($token) => $this: $r');
    return r;
  }
}

class And extends Parser {
  _Parser first;
  _Parser second;
  And(this.first, this.second);

  // toString() => 'And($first, $second)';

  bool get nullable => this.first.nullable && this.second.nullable;
  bool get empty => this.first.empty || this.second.empty;

  Parser derive(token){
    print('_ ($token) => $this');
    var r;
    if (this.first.nullable){
      var left = new And(this.first.derive(token), this.second);
      var right = new And(new Null(this.first.parseNull()),
          this.second.derive(token));
      r = new Or(left, right);
    } else {
      r = new And(this.first.derive(token), this.second);
    }
    print('_ ($token) => $this: $r');
    return r;
  }

  MySet parseNull(){
    print('_ => $this');
    MySet result = new MySet();
    for ( var l in this.first.parseNull()) {
      for (var r in this.second.parseNull())
        result.add(new MySet.from([l,r]));
    }
    print('_ $this: $result');
    return result;
  }
}

class Or extends Parser {
  _Parser first;
  _Parser second;
  Or(this.first, this.second);

  // toString() => 'Or($first, $second)';

  bool get nullable => this.first.nullable || this.second.nullable;
  bool get empty => this.first.empty && this.second.empty;

  Parser derive(token){
    print('_ ($token) => $this');
    var r;
    if (this.first.empty){
      r = this.second.derive(token);
    } else
    if (this.second.empty){
      r = this.first.derive(token);
    } else
      r = new Or(first.derive(token), second.derive(token));

    print('_ ($token) => $this: $r');
    return r;
  }

  MySet parseNull(){
    print('_ $this');
    MySet result = new MySet();
    result.addAll(this.first.parseNull());
    result.addAll(this.second.parseNull());
    print('_ $this: $result');
    return result;
  }
}

class Reduce extends Parser {
  Parser parser;
  Function reduction;

  bool get nullable => this.parser.nullable;
  bool get empty => this.parser.empty;

  Reduce(this.parser, this.reduction);

  // toString() => 'Reduce($parser)';

  Parser derive(token) {
    print('_ ($token) => $this');
    var r = new Reduce(parser.derive(token), this.reduction);
    print('_ ($token) => $this: $r');
    return r;
  }

  MySet parseNull(){
    print('_ $this');
    MySet result = new MySet();
    MySet parseNull = parser.parseNull();

    for( final r in parseNull){
      result.add(reduction(r));
    }
    print('_ $this: $result');
    return result;
  }
}

class KleeneStar extends Parser {
  Parser _parser;
  bool isNullable_called = false;
  bool isNullable_value = false;
  bool isEmpty_called = false;
  bool isEmpty_value = true;
  bool parseNull_called = false;
  MySet parseNull_value = new MySet();
  var cache = new Map<dynamic, Parser>();
  
  set parser(p) {
    print(p);
    _parser = p;
    isNullable_called = false;
    isNullable_value = false;
    isEmpty_called = false;
    isEmpty_value = true;
    parseNull_called = false;
    parseNull_value = new MySet();
    cache = new Map<dynamic, Parser>();
    print('done');
  }

  get nullable {
    if(isNullable_called)
      return isNullable_value;
    isNullable_called = true;
    var value;    
    while (true) {
      value = _parser.nullable;
      if (isNullable_value == value)
        break;
      isNullable_value = value;
    }
    return value;
  }
  bool get empty {
    if (isEmpty_called)
      return isEmpty_value;
    
    isEmpty_called = true;
    var value;
    while(true) {
      value = _parser.empty;
      if (isEmpty_value == value)
        break;
      isEmpty_value = value;
    }
    return value;
  }

  MySet parseNull(){
    if (parseNull_called)
      return parseNull_value;

    parseNull_called = true;
    var value;
    while(true){
      value = _parser.parseNull();
      if (parseNull_value == value)
        break;
      parseNull_value = value;
    }
    return value;
  }

  Parser derive(token){
    var r = cache.putIfAbsent(token, () => _parser.derive(token));
    print(r);
    return r;
  }

  // toString() => 'KleeneStar($_parser)';
}


T(token) => new Token(token);
var _ = new Null();

main(){
  log.on.record.add((r) {
    if(r.loggerName == 'parse') print('${r.message}');
    });
  dlog.on.record.add((r) {
    if(r.loggerName == 'derive') print('derive: ${r.message}');
    });
  nlog.on.record.add((r) {
    if(r.loggerName == 'parseNull') print('parseNull: ${r.message}');
    });

//  var f = new KleeneStar();
//  var bbb = T('b') + f | new Null();
  var bbb = T('b') *_;
//  f._parser = bbb;
  print(bbb.parse(['b','b','b','b']));
  
  //var p = T('import') + T('lib');
  //var i = p + T('a');
  //print(p.parse(['import', 'lib']));
  //  print(i.parse(['import', 'lib', 'a']));

  //var o = T('import') + T('a') | T('lib');
  //  print(o.parse(['import', 'a']));
}
