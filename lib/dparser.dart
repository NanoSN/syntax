library mine;

import 'dart:collection';
import 'package:logging/logging.dart';

var log = new Logger('parse');
var dlog = new Logger('derive');
var nlog = new Logger('parseNull');

class MySet<E> implements List<E> {
  var list = new List();
  MySet._internal([int length = 0]) {
    list = new List(length);
  }
  factory MySet([int length = 0]) {
    return new MySet._internal(length);
  }
  
  factory MySet.fixedLength(int length, {E fill: null}){
    var set = new MySet();
    set.list = new List.fixedLength(length, fill:fill);
    return set;
  }
  
  factory MySet.from(Iterable other) {
    MySet set = new MySet();
    for (final e in other) {
      set.add(e);
    }
    return set;
  }

  operator ==(MySet other) {
    var o = new List.from(other);
    o = this.list.where((_) => !other.contains(_));
    return o.length == 0;
    //o.retainAll(this.list);
    //return o.length == this.list.length
    //  && o.length == other.list.length;
  }

  get hashCode {
    int hc = 0;
    for (final e in this) {
      hc << e.hashCode;
    }
    return hc;
  }

  E operator [](int index) => list[index];
  void operator []=(int index, E value) {list[index] = value;}
  void set length(int newLength) {list.length = newLength;}
  void add(E value) {list.add(value);}
  void addLast(E value) {list.addLast(value);}
  void addAll(Iterable<E> iterable){list.addAll(iterable);}
  List<E> get reversed => list.reversed;
  void sort([int compare(E a, E b)]) {list.sort(compare);}

  int indexOf(E element, [int start = 0]) => list.indexOf(element, start);
  int lastIndexOf(E element, [int start]) => list.lastIndexOf(element, start);
  void clear(){list.clear();}
  void remove(Object element) => list.remove(element);
  E removeAt(int index) => list.removeAt(index);
  E removeLast() => list.removeLast();
  List<E> getRange(int start, int length) => list.getRange(start, length);
  void setRange(int start, int length, List<E> from, [int startFrom]){
    list.setRange(start, length, from, startFrom);}
  void removeRange(int start, int length) {list.removeRange(start,length);}
  void insertRange(int start, int length, [E fill]) {
    list.insertRange(start, length, fill);}
  Iterator<E> get iterator => list.iterator;
  String toString() => list.toString();
  E get first => list.first;
  void retainAll(other) => list.retainAll(other);
  List<E> toList() => list.toList();
  bool get isEmpty => list.isEmpty;
}

abstract class _Parser {
  bool get nullable;
  bool get empty;
  Parser derive(token);
  MySet parseNull();
}

abstract class Parser extends _Parser {
  And operator +(Parser other) {
    if(other == null)
      oneOrMore();
    return new And(this, other);
  }
  Or operator |(Parser other) => new Or(this, other);
  Or operator %(Parser other) => zeroOrOne();
  Parser operator *(Parser other) => zeroOrMore();
  Reduce operator <=(Function reduction) => new Reduce(this, reduction);

  /// represents 'a?'
  Parser zeroOrOne() {
    if (empty) return this;
    if (nullable) return new Null();
    return new Or(new Empty(), this);
  }
  
  ///represents 'a+'
  Parser oneOrMore() {
    if (empty) return this;
    if (nullable) return new Empty();
    return this + (this *_);
  }

  ///represents 'a*'
  Parser zeroOrMore() {
    if (empty) return this;
    if (nullable) return new Null();
    var star = new KleeneStar();
    star.parser = this + star | new Null();
    return star;
  }
  

  MySet parse(List tokens){
    var parser = this;
    var pass = 0;
    for( var token in tokens){
      pass += 1;
      print('PASS: $pass');
      parser = parser.derive(token);
      print(parser.parseNull());
    }
    print('Done parsing');
    print(parser);
    return parser.parseNull();
  }
}

class Empty extends Parser {
  bool get nullable => false;
  bool get empty => true;

  MySet parseNull() {
    var r = new MySet();
    print('EMPTY $r');
    return r;
  }
  Parser derive(token) {
    var r = new Empty();
    return r;
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
    print('NULL $r');
    return r;
  }

  Parser derive(token) {
    var r = new Empty();
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
    print('TOKEN $r');
    return r;
  }
  Parser derive(token){
    var r = new Empty();
    if (this.token == token){
      r = new Null(new MySet.from([token]));
    }
    return r;
  }
}

class CallForEqulity extends Parser {
  Function isEqual;
  CallForEqulity(this.isEqual);

  bool get nullable => false;
  bool get empty => false;
  MySet parseNull() {
    var r = new MySet();
    print('CALLFOREQULITY $r');
    return r;
  }
  Parser derive(token){
    var r = new Empty();
    if (isEqual(token)){
      r = new Null(new MySet.from([token]));
    }
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
    var r;
    if (this.first.nullable){
      var left = new And(this.first.derive(token), this.second);
      var right = new And(new Null(this.first.parseNull()),
          this.second.derive(token));
      r = new Or(left, right);
    } else {
      r = new And(this.first.derive(token), this.second);
    }
    return r;
  }

  MySet parseNull(){
    MySet result = new MySet();
    if(first == null && second == null) return result;
    if(first == null && second != null) return second.parseNull();
    if(first != null && second == null) return first.parseNull();

    var f = first.parseNull().isEmpty;
    var s = second.parseNull().isEmpty;
    print('First: ${this.first.parseNull()}');
    print('Second: ${this.second.parseNull()}');
    if(first.parseNull().isEmpty) return second.parseNull();
    if(second.parseNull().isEmpty) return first.parseNull();    
    


    for ( var l in this.first.parseNull()) {
      for (var r in this.second.parseNull()){
        result.add(new MySet.from([l,r]));
      }
    }
    print('AND r:$result f:${first.parseNull()}, s:$second');
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
    var r;
    if (this.first.empty){
      r = this.second.derive(token);
    } else
    if (this.second.empty){
      r = this.first.derive(token);
    } else
      r = new Or(first.derive(token), second.derive(token));

    return r;
  }

  MySet parseNull(){
    MySet result = new MySet();
    result.addAll(this.first.parseNull());
    result.addAll(this.second.parseNull());
    print('OR $result');
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
    var r = new Reduce(parser.derive(token), this.reduction);
    return r;
  }

  MySet parseNull(){
    MySet result = new MySet();
    MySet parseNull = parser.parseNull();

    for( final r in parseNull){
      result.add(reduction(r));
    }
    print('REDUCE $result');
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
    _parser = p;
    isNullable_called = false;
    isNullable_value = false;
    isEmpty_called = false;
    isEmpty_value = true;
    parseNull_called = false;
    parseNull_value = new MySet();
    cache = new Map<dynamic, Parser>();
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
    if (parseNull_called){
      print('KLEENESTAR_called $parseNull_value');
      return parseNull_value;
    }

    parseNull_called = true;
    var value;
    while(true){
      value = _parser.parseNull();
      if (parseNull_value == value)
        break;
      parseNull_value = value;
    }
    print('KLEENESTAR $value');    
    return value;
  }

  Parser derive(token){
    var r = cache.putIfAbsent(token, () => _parser.derive(token));
    return r;
  }

  // toString() => 'KleeneStar($_parser)';
}


TT(token) => new Token(token);
var _ = new Null();
S() => new KleeneStar();

P(bool equals(dynamic token)) => new CallForEqulity(equals);

main(){

  //  var bee = T('b') <= ((a) {print('BBBB: $a'); return a;});
  //  var bees = bee * _;
  //  var r = bees;
  //  print(r.parse(['b','b','b','b']));

  /// Need to figure out equlity .. everything must be hashable.
  var f = new KleeneStar();
  var bbb = new Or(  new Reduce(
                         new And(  TT('b'), f  ),
                         (a) {
                           print('BBBB: "$a"');
                           var b = a.toList()[0];
                           var c = a.toList()[1];
                           print('b,c: $b, $c');
                           var r = new MySet()..addAll(b)..addAll([c]);
                           print('r: $r');
                           return r;
                         }),
                     new Reduce(
                         new Null(),
                         (a) {
                           print('Null: "$a"');
                           return new MySet();
                         })
                 );
  
//  var bbb = T('b') *_;
  f._parser = bbb;
    print(bbb.parse(['b','b','b','b']));
}
