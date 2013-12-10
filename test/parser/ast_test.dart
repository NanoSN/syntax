import 'package:unittest/unittest.dart';
import 'package:syntax/parser.dart';

main(){
  group('Ast', (){
    test('AstList', (){
      var alist = new AstList();
      var blist = new AstList();
      expect(alist, equals(blist));
    });

    test('Non empty AstList', (){
      var alist = new AstList();
      var node = new AstNode();
      alist.add(node);
      var blist = new AstList();
      blist.add(node);
      expect(alist, equals(blist));
      expect(alist == blist, isTrue);
    });
  });
}
