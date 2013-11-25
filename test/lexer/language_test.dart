
import 'package:unittest/unittest.dart';
import 'package:syntax/lexer.dart';

main(){
  group('Core', (){
    test('Empty Language', (){
      expect(const Reject().derive('c'), equals(reject));
    });

    test('Match Language', (){
      expect(const Reject().derive('c'), equals(reject));
    });

    group('Character Language', (){
      test('character matches', (){
        expect(new Character('c').derive('c'), equals(match));
      });

      test("character doesn't matches", (){
        expect(new Character('c').derive('b'), equals(reject));
      });
    });
  });

  group('Or Operation', (){
    test('left match', (){
      var lang = makeOr(new Character('a'), new Character('b'));
      expect(lang.derive('a'), equals(match));
    });
    test('right match', (){
      var lang = makeOr(new Character('a'), new Character('b'));
      expect(lang.derive('b'), equals(match));
    });
    test('no match', (){
      var lang = makeOr(new Character('a'), new Character('b'));
      expect(lang.derive('c'), equals(reject));
    });
    test('3 options match', (){
      var lang = makeOr(makeOr(new Character('a'), new Character('b')),
                        new Character('c'));
      expect(lang.derive('a'), equals(match));
      expect(lang.derive('b'), equals(match));
      expect(lang.derive('c'), equals(match));
    });
  });

  group('And Operation', (){
    test('basic match', (){
      var lang = makeAnd(new Character('a'), new Character('b'));
      lang = derive(lang, 'ab');
      expect(lang, equals(match));
    });
    test('basic no match', (){
      var lang = makeAnd(new Character('a'), new Character('b'));
      lang = derive(lang, 'aa');
      expect(lang, equals(reject));
    });
    test('match 3 letters', (){
      var langAB = makeAnd(new Character('a'), new Character('b'));
      var langABC = makeAnd(langAB, new Character('c'));
      var lang = derive(langABC, 'abc');
      expect(lang, equals(match));

      langABC = makeAnd(new Character('c'), langAB);
      lang = derive(langABC, 'cab');
      expect(lang, equals(match));
    });
    test('no match 3 letters', (){
      var langAB = makeAnd(new Character('a'), new Character('b'));
      var langABC = makeAnd(langAB, new Character('c'));
      var lang = derive(langABC, 'aac');
      expect(lang, equals(reject));
      lang = derive(langABC, 'aba');
      expect(lang, equals(reject));
    });
    test('match 4 letters', (){
      var langAB = makeAnd(new Character('a'), new Character('b'));
      var lang = makeAnd(langAB, langAB);
      lang = derive(lang, 'abab');
      expect(lang, equals(match));
    });
    test('no match 4 letters', (){
      var langAB = makeAnd(new Character('a'), new Character('b'));
      var lang = makeAnd(langAB, langAB);
      lang = derive(lang, 'abaa');
      expect(lang, equals(reject));
      lang = derive(lang, 'aba');
      expect(lang, equals(reject));
    });

    group('Star Operation', (){
      test('match', (){
        var lang = makeAnd(makeStar(new Character('a')),
                           makeStar(new Character('b')));
        lang = derive(lang, 'aaabbb');
        expect(lang, equals(match));

        var langABs = makeAnd(new Character('a'), makeStar(new Character('b')));
        lang = derive(langABs, 'a');
        expect(lang, equals(match));
        lang = derive(langABs, 'ab');
        expect(lang, equals(match));
        lang = derive(langABs, 'abbbb');
        expect(lang, equals(match));
      });

      test('no match', (){
        var lang = makeAnd(makeStar(new Character('a')),
                           makeStar(new Character('b')));
        lang = derive(lang, 'aaabbbc');
        expect(lang, equals(reject));

        var langABs = makeAnd(new Character('a'), makeStar(new Character('b')));
        lang = derive(langABs, 'aa');
        expect(lang, equals(reject));
        lang = derive(langABs, 'abbbc');
        expect(lang, equals(reject));
        lang = derive(langABs, 'abbbbbbbbbb.');
        expect(lang, equals(reject));
      });

    });
  });
}
/// Helper function that does all the heavy lifting.
derive(lang, str, {dbg:false}) {
  // We add this special char as part of matcher.
  lang = makeAnd(lang, EOI);
  //str = '${str}';
  if(dbg)print('$lang: $str');
  for(var i=0; i< str.length; i++){
    lang = lang.derive(str[i]);
    if(dbg)print('$lang: ${str.substring(i+1)}');
  }
  lang = lang.derive(EOI);
  return lang;
}
