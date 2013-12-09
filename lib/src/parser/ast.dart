part of parser;

class AstList extends ListBase<AstNode> {
//class AstList extends HashSet<AstNode> {
  int hashCode = -1;
  List<AstNode> _list = new List<AstNode>();

  int get length => _list.length;
  int set length(int newLength) => _list.length = newLength;

  AstNode operator [](int index) => _list[index];

  void operator []=(int index, AstNode value) {
    hashCode -= _list[index].hashCode;
    hashCode += value.hashCode;
    _list[index] = value;
  }


  void clear() {
    super.clear();
    hashCode = -1;
  }

  bool remove(Object value) {
    var r =  super.remove(value);
    if(r) hashCode -= value.hashCode;
    return r;
  }

  AstNode removeAt(int index){
    var r =  super.removeAt(index);
    hashCode -= r.hashCode;
    return r;
  }

  AstNode removeLast() => removeAt(length - 1);
  void removeWhere(bool test(E element)) => throw 'Not Supported.';
  void retainWhere(bool test(E element)) => throw 'Not Supported.';

  operator ==(AstList other) {
    return hashCode == other.hashCode;
  }
}

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
