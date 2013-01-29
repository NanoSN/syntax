
import 'dart:collection';

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


abstract class Parser {
  Parser derive(ch);
  Set deriveNull();
}

class Literal extends Parser
{
  final ch;

  Literal(this.ch);

  Parser derive(ch){
    return this.ch == ch ? new Epsilon(ch) : new Empty();
  }

  Set deriveNull() {
    print('Litral.deriveNull: $ch');
    return new MySet();
  }
}


class Empty extends Parser {
  Parser derive(ch) {
    return new Empty();
  }
  
  Set deriveNull(){
    print('Empty.deriveNull');
    return new MySet();
  }
}


class Epsilon extends Parser {
  Set trees = new MySet();

  Epsilon([ch]){
    ?ch? trees.add(ch) : trees.add("");
  }

  Parser derive(ch) {
    return new Empty();
  }

  Set deriveNull() {
    print('Epsilon.deriveNull: $trees');
    return trees;
  }
}

class Delta extends Parser
{
  Parser l;

  Delta(this.l);
  
  Parser derive(ch) {
    return new Empty();
  }

  Set deriveNull(){
    print('Delta.deriveNull: $l');    
    return l.deriveNull();
  }
}

abstract class Fix extends Parser
{
  
  Parser innerDerive(ch);
  Set innerDeriveNull();

  static Map derivatives = new Map<dynamic, Parser>();

  Parser derive(ch) {
    //return derivatives.putIfAbsent(ch, () => new Delay(this, ch));
    if (! derivatives.containsKey(ch))
    {
      derivatives[ch] = new Delay(this, ch);
    }
    return derivatives[ch];
  }

  Set deriveNull() {
    print('Fix.deriveNull: $this');
    if (_set != null) return _set;

    Set newSet = new MySet();
    do {
      _set = newSet;
      newSet = innerDeriveNull();
      var r = _set == newSet;
      print('$_set == $newSet? $r');
    } while ( _set != newSet );
    return _set;
  }
  
  Set _set = null;
}

class Delay extends Parser {
    Fix parser;
    var ch;
    Parser derivative = null;
    
    Delay(Fix parser, ch)
    {
      this.parser = parser;
      this.ch = ch;
    }

    Parser derive(ch) {
      this.force();
      return this.derivative.derive(ch);
    }

    Set deriveNull() {
      print('Delay.deriveNull: $parser');      
      this.force();
      return this.derivative.deriveNull();
    }
    
    void force() {
      if (derivative == null)
      {
        derivative = this.parser.innerDerive(this.ch);
      }
    }
}
class Alternative extends Fix
{
  Parser l1;
  Parser l2;

  Alternative(Parser l1, Parser l2){
    this.l1 = l1;
    this.l2 = l2;
  }

  Parser innerDerive(ch) {
    return new Alternative( l1.derive(ch), l2.derive(ch) );
  }

  Set innerDeriveNull() {
    print('Alternative.innerDeriveNull');          
    final Set set = new MySet();
    set.addAll( l1.deriveNull() );
    set.addAll( l2.deriveNull() );
    return set;
  }
}


class Concat extends Fix
{
  Parser l1;
  Parser l2;

  Concat(Parser l1, Parser l2)
  {
    this.l1 = l1;
    this.l2 = l2;
  }

  Parser innerDerive(ch)
  {
    return new Alternative(
        new Concat( l1.derive(ch), l2 ),
        new Concat( new Delta(l1), l2.derive(ch) )
        );
  }
  
  Set innerDeriveNull()
  {
    print('Concat.innerDeriveNull');
    Set set1 = l1.deriveNull();
    Set set2 = l2.deriveNull();
    Set result = new MySet();
    for (Object o1 in set1)
    {
      for (Object o2 in set2)
      {
        result.add( new Set.from([o1,o2]));
      }
    }
    return result;
  }
}

class Reduce extends Fix
{
  Parser parser;
  Function reduction;

  Reduce(Parser parser, Function reduction)
  {
    this.parser    = parser;
    this.reduction = reduction;
  }

  Parser innerDerive(ch) {
    return new Reduce(parser.derive(ch),reduction);
  }

  Set innerDeriveNull()
  {
    print('Reduce.innerDeriveNull');    
    Set newSet = new MySet();
    for (final o in parser.deriveNull()){
      newSet.add( reduction(o) );
    }
    return newSet;
  }
}

class Recurrence extends Fix
{
    Parser l;
    
    void setParser(Parser l) { this.l = l; }
    
    Parser innerDerive(ch){
      return l.derive(ch);
    }

    Set innerDeriveNull(){
      print('Recurrence.innerDeriveNull');
      return l.deriveNull();
    }    
}

main(){
  var reduction = (m) => m;
  var S = new Recurrence();
  var a = new Alternative(new Epsilon(), new Reduce(new Concat(S, new Literal('1')), reduction));
  S.setParser(a);
  
  for (var ch in "11111".splitChars())
  {
    a = a.derive(ch);
  }
  print( a.deriveNull() );
}


