
import 'package:unittest/unittest.dart';
import 'package:parse/lexer/language.dart';

main(){
  group('Core', (){
    test('Empty Language', (){
      expect(new Empty().derive('c'), equals(empty));
    });

    test('Match Language', (){
      expect(new Match().derive('c'), equals(empty));
    });

    group('Character Language', (){
      test('character matches', (){
        expect(new Character('c').derive('c'), equals(match));
      });

      test("character doesn't matches", (){
        expect(new Character('c').derive('b'), equals(empty));
      });
    });
  });

  group('Or Operation', (){
    test('left match', (){
      var lang = new Or(new Character('a'), new Character('b'));
      expect(lang.derive('a'), equals(match));
    });
    test('right match', (){
      var lang = new Or(new Character('a'), new Character('b'));
      expect(lang.derive('b'), equals(match));
    });
    test('no match', (){
      var lang = new Or(new Character('a'), new Character('b'));
      expect(lang.derive('c'), equals(empty));
    });
    test('3 options match', (){
      var lang = new Or(new Or(new Character('a'), new Character('b')),
                        new Character('c'));
      expect(lang.derive('a'), equals(match));
      expect(lang.derive('b'), equals(match));
      expect(lang.derive('c'), equals(match));
    });
  });

  group('And Operation', (){
    test('basic match', (){
      var lang = new And(new Character('a'), new Character('b'));
      lang = derive(lang, 'ab');
      expect(lang, equals(match));
    });
    test('basic no match', (){
      var lang = new And(new Character('a'), new Character('b'));
      lang = derive(lang, 'aa');
      expect(lang, equals(empty));
    });
    test('match 3 letters', (){
      var langAB = new And(new Character('a'), new Character('b'));
      var langABC = new And(langAB, new Character('c'));
      var lang = derive(langABC, 'abc');
      expect(lang, equals(match));

      langABC = new And(new Character('c'), langAB);
      lang = derive(langABC, 'cab');
      expect(lang, equals(match));
    });
    test('no match 3 letters', (){
      var langAB = new And(new Character('a'), new Character('b'));
      var langABC = new And(langAB, new Character('c'));
      var lang = derive(langABC, 'aac');
      expect(lang, equals(empty));
      lang = derive(langABC, 'aba');
      expect(lang, equals(empty));
    });
    test('match 4 letters', (){
      var langAB = new And(new Character('a'), new Character('b'));
      var lang = new And(langAB, langAB);
      lang = derive(lang, 'abab');
      expect(lang, equals(match));
    });
    test('no match 4 letters', (){
      var langAB = new And(new Character('a'), new Character('b'));
      var lang = new And(langAB, langAB);
      lang = derive(lang, 'abaa');
      expect(lang, equals(empty));
      lang = derive(lang, 'aba');
      expect(lang, equals(empty));
    });
  });
}
/// Helper function that does all the heavy lifting.
derive(lang, str, {dbg:false}) {
  if(dbg)print('$str $lang');
  for(var i=0; i< str.length; i++){
    lang = lang.derive(str[i]);
    if(dbg)print('$str $lang');
  }
  return lang;
}
