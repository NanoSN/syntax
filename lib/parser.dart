library parse;
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
  Reduce operator <=(Function reduction) => new Reduce(this, reduction);

  MySet parse(List tokens){
    var parser = this;
    for( var token in tokens){
      log.info('$parser');
      parser = parser.derive(token);
    }
    log.info('done: $parser');
    //return parser.parseNull();
  }
}

class Empty extends Parser {
  bool get nullable => false;
  bool get empty => true;

  MySet parseNull() {
    var r = new MySet();
    nlog.info('$this: $r');
    return r;
  }
  Parser derive(token) {
    var r = new Empty();
    dlog.info('($token) => $this: $r');
    return r;
  }

  /// singleton factory
  static final _instance = new Empty._internal();
  factory Empty() => _instance;
  Empty._internal();
  toString() => 'Empty';
}

class Null extends Parser {
  MySet result = new MySet.from(['']);
  bool get nullable => true;
  bool get empty => false;
  toString() => 'Null($result)';

  MySet parseNull() {
    var r = this.result;
    nlog.info('$this: $r');
    return r;
  }

  Parser derive(token) {
    var r = new Empty();
    dlog.info('($token) => $this: $r');
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
    if (?result){
      this.result = new MySet.from(result);
    }
  }
}

class Token extends Parser {
  var token;
  Token(this.token);

  bool get nullable => false;
  bool get empty => false;

  toString() => 'Token($token)';

  MySet parseNull() {
    var r = new MySet();
    nlog.info('$this: $r');
    return r;
  }
  Parser derive(token){
    var r = new Empty();
    if (this.token == token){
      r = new Null(new MySet.from([token]));
    }
    dlog.info('($token) => $this: $r');
    return r;
  }
}

class And extends _Fix {
  _Parser first;
  _Parser second;
  And(this.first, this.second);

  toString() => 'And($first, $second)';

  bool get nullable => this.first.nullable && this.second.nullable;
  bool get empty => this.first.empty || this.second.empty;

  Parser _derive(token){
    dlog.info('_ ($token) => $this');
    var r;
    if (this.first.nullable){
      var left = new And(this.first.derive(token), this.second);
      var right = new And(new Null(this.first.parseNull()),
          this.second.derive(token));
      r = new Or(left, right);
    } else {
      r = new And(this.first.derive(token), this.second);
    }
    dlog.info('_ ($token) => $this: $r');
    return r;
  }

  MySet _parseNull(){
    nlog.info('_ => $this');
    MySet result = new MySet();
    for ( var l in this.first.parseNull()) {
      for (var r in this.second.parseNull())
        result.add(new MySet.from([l,r]));
    }
    nlog.info('_ $this: $result');
    return result;
  }
}

class Or extends _Fix {
  _Parser first;
  _Parser second;
  Or(this.first, this.second);

  toString() => 'Or($first, $second)';

  bool get nullable => this.first.nullable || this.second.nullable;
  bool get empty => this.first.empty && this.second.empty;

  Parser _derive(token){
    dlog.info('_ ($token) => $this');
    var r;
    if (this.first.empty){
      r = this.second.derive(token);
    } else
    if (this.second.empty){
      r = this.first.derive(token);
    } else
      r = new Or(first.derive(token), second.derive(token));

    dlog.info('_ ($token) => $this: $r');
    return r;
  }

  MySet _parseNull(){
    nlog.info('_ $this');
    MySet result = new MySet();
    result.addAll(this.first.parseNull());
    result.addAll(this.second.parseNull());
    nlog.info('_ $this: $result');
    return result;
  }
}

class Reduce extends _Fix {
  Parser parser;
  Function reduction;

  bool get nullable => this.parser.nullable;
  bool get empty => this.parser.empty;

  Reduce(this.parser, this.reduction);

  toString() => 'Reduce($parser)';

  Parser _derive(token) {
    dlog.info('_ ($token) => $this');
    var r = new Reduce(parser.derive(token), this.reduction);
    dlog.info('_ ($token) => $this: $r');
    return r;
  }

  MySet _parseNull(){
    nlog.info('_ $this');
    MySet result = new MySet();
    MySet parseNull = parser.parseNull();

    for( final r in parseNull){
      result.add(reduction(r));
    }
    nlog.info('_ $this: $result');
    return result;
  }
}

class KleeneStar extends _Parser {
  Parser parser;
  bool get nullable => parser.nullable;
  bool get empty => parser.empty;
  Parser derive(token) => parser.derive(token);
  MySet parseNull() {
    nlog.info('$this');
    var r = parser.parseNull();
    nlog('$this: $r');
    return r;
  }
  toString() => 'KleeneStar($parser)';
}

abstract class _Fix extends Parser {
  Parser _derive(token);
  MySet _parseNull();

  toString() => '_Fix';
  static var _memoize = new Map<String, Parser>();

//  Parser derive(token) => _memoize.putIfAbsent(token, () =>
//      new _Lazy(this, token));

  Parser derive(token) {
    var r = _memoize.putIfAbsent(token, () => new _Lazy(this, token));
    dlog.info('($token) => $this: $r');
    return r;
  }

  MySet _result = null;
  MySet parseNull() {
    nlog.info('$this');
    if (_result != null) {
      nlog.info('$this: $_result');
      return _result;
    }
    MySet result = new MySet();
    do {
      _result = result;
      result = this._parseNull();
      var r = _result == result;
      nlog.info('$_result == $result = $r');
    } while (_result != result);
    nlog.info('$this: $result');
    return _result;
  }
}

class _Lazy extends Parser {

  _Fix parser;
  dynamic token;
  Parser _derivative = null;

  toString() => '_Lazy($parser): T:$token, D:$_derivative';

  Parser get derivative {
    if(_derivative == null){
      _derivative = parser._derive(token);
    }
    return _derivative;
  }

  _Lazy(parser, token){
    if(parser is! _Fix) throw 'No way';
    this.parser = parser;
    this.token = token;
  }

  bool get nullable => parser.nullable;
  bool get empty => parser.empty;

  Parser derive(token){
    dlog.info('($token) => $this');
    var r = derivative.derive(token);
    dlog.info('($token) => $this: $r');
    return r;
  }
//  MySet parseNull() => derivative.parseNull();

/// Using force instead of getter
//  Parser derive(token) {
//    force();
//    return _derivative.derive(token);
//  }

  MySet parseNull() {
    nlog.info('$this');
    force();
    var r = _derivative.parseNull();
    nlog.info('$this: $r');
    return r;
  }

  void force(){
    if(_derivative == null){
      _derivative = parser._derive(token);
    }
  }
}

T(token) => new Token(token);
var _ = null;

main(){
  var p = T('import') + T('lib');
  var i = p + T('a');

  log.on.record.add((r) {
    if(r.loggerName == 'parse') print('${r.message}');
    });
  dlog.on.record.add((r) {
    if(r.loggerName == 'derive') print('derive: ${r.message}');
    });
  nlog.on.record.add((r) {
    if(r.loggerName == 'parseNull') print('parseNull: ${r.message}');
    });


  
  //print(p.parse(['import', 'lib']));
  print(i.parse(['import', 'lib', 'a']));

  //var o = T('import') + T('a') | T('lib');
  //  print(o.parse(['import', 'a']));

    /*
  var S = new KleeneStar();
  var a = new Or(
      new Null(),
      new Reduce(
          new And(
              S,
              new Token('1')),
          (bla) {return bla;}
        )
      );

  S.parser = a;
  print(a.parse(['1','1','1']));
  */

}

class ImportNode {
  var lib;
  ImportNode(this.lib);
  toString() => 'import $lib';
}
