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

  AstNode() : hashCode = ++_HASH_COUNTER;

  AstNode parent;
  final List<AstNode> children = <AstNode>[];
  final List<Token> tokens = <Token>[];
  toString(){
    return _toString();
  }

  repr() => '';

  String _toString({String prefix:'', bool isTail:true}) {
    var sb = new StringBuffer();
    sb..write(prefix)
      ..write(isTail? '└── ': '├── ')
      ..writeln('$runtimeType ${repr()}');

    if( children.isEmpty ) return sb.toString();

    children.take(children.length - 1).forEach( (child) {
      var _prefix = prefix + (isTail ? '    ' : '│   ');
      sb.write(child._toString(
                          prefix:_prefix,
                          isTail:false));
    });
    sb.write(children.last._toString(
                                prefix: prefix + (isTail ? '    ' : '│   '),
                                isTail: true));
    return sb.toString();
  }
}
