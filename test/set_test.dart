
import 'package:unittest/unittest.dart';
import 'package:parse/parser.dart';

main(){
  group('set equality', () {
    test('are equal', () {
      Set s1 = new MySet.from(['1', '2', '3']);
      Set s2 = new MySet.from(['1', '2', '3']);
      expect(s1 == s2, isTrue);
    });

    test('are not equal', () {
      Set s1 = new MySet.from(['1', '2', '3']);
      Set s2 = new MySet.from(['1', '2', '3', '4']);
      expect(s1 == s2, isFalse);
    });
  });

  group('sets inside a set equality', () {
    test('are equal', () {
      MySet s1 = new MySet.from([new MySet.from(['1', '2', '3'])]);
      MySet s2 = new MySet.from([new MySet.from(['1', '2', '3'])]);
      expect(s1 == s2, isTrue);
    });

    test('are not equal', () {
      Set s1 = new MySet.from([new MySet.from(['1', '2', '3'])]);
      Set s2 = new MySet.from([new MySet.from(['1', '2', '4a'])]);
      expect( s1 == s2, isFalse);
    });
  });

  group('sets inside a set equality', () {
    test('are equal', () {
      MySet s1 = new MySet();
      s1.addAll([['1', '2', '3']]);
      print(s1);
      MySet s2 = new MySet.from([new MySet.from(['1', '2', '3'])]);
      expect(s1 == s2, isTrue);
    });

    test('are not equal', () {
      Set s1 = new MySet.from([new MySet.from(['1', '2', '3'])]);
      Set s2 = new MySet.from([new MySet.from(['1', '2', '4a'])]);
      expect( s1 == s2, isFalse);
    });
  });
  bla();
  bla('sadf');
}

void bla([b]){
  ?b? print(b) : print('wwwwwwwwww');
  (b != null)? print(b) : print('aaaaaaaaaaaaa');
}
