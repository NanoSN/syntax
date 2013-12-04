import 'package:unittest/unittest.dart';
import 'package:syntax/parser.dart';


main(){
  GLOBAL_INSPECTION.add((_) {
    if(_ is And || _ is Or)
      print('${_.runtimeType}(${_.left.runtimeType}, ${_.right.runtimeType})');
    if(_ is Star)
      print('${_.runtimeType}(${_.parser.runtimeType})');
  });

  group('Parser Language Tests', (){
    test('TokenParser', (){
      Parser parser = new TokenParser(new TokenDefinition(value:'var'));
      var derivative = parser.derive(new Token('var'));
      expect(derivative is Match, isTrue);
    });

    test('And', (){
      Parser left = new TokenParser(new TokenDefinition(value:'var'));
      Parser right = new TokenParser(new TokenDefinition(value:'a'));
      Parser and = makeAnd(left, right);
      var derivative = and.derive(new Token('var')).derive(new Token('a'));
      var tokens = derivative.toAst();
      expect(derivative is Match, isTrue);
      expect(tokens.length, equals(2));
    });
    test('And and', (){
      Parser left = new TokenParser(new TokenDefinition(value:'var'));
      Parser right = new TokenParser(new TokenDefinition(value:'a'));
      Parser and = makeAnd(left, right);
      Parser parser = makeAnd(and, new TokenParser(new TokenDefinition(value:'=')));
      var derivative = parser.derive(new Token('var'))
                          .derive(new Token('a'))
                          .derive(new Token('='));
      var tokens = derivative.toAst();
      expect(derivative is Match, isTrue);
      expect(tokens.length, equals(3));
    });
    test('Or', (){
      Parser left = new TokenParser(new TokenDefinition(value:'var'));
      Parser right = new TokenParser(new TokenDefinition(value:'a'));
      Parser or = makeOr(left, right);
      var derivative = or.derive(new Token('var'));
      var ast = derivative.toAst();
      expect(derivative is Match, isTrue);
      expect(ast.length, equals(1));
    });
    test('Reduce', (){
      Parser left = new TokenParser(new TokenDefinition(value:'var'));
      Parser right = new TokenParser(new TokenDefinition(value:'a'));
      Parser and = makeAnd(left, right);
      Parser parser = makeReduce(and, (nodes) =>
          nodes.reduce((r,_) => r..tokens.addAll(_.tokens)
                                 ..children.addAll(_.children)));
      var derivative = parser.derive(new Token('var')).derive(new Token('a'));
      var ast = derivative.toAst();
      expect(derivative is Match, isTrue);
      expect(ast.length, equals(1));
    });
    test('Star', (){
      Parser a = new TokenParser(new TokenDefinition(value:'a'));
      Parser parser = makeStar(a);
      var derivative = parser.derive(new Token('a')).derive(new Token('a'));
      var ast = derivative.toAst();
      expect(derivative is And, isTrue);
      expect(ast.length, equals(2));
    });
  });
}
