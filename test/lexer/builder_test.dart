
import 'package:unittest/unittest.dart';
import 'package:parse/lexer/language.dart';
import 'package:parse/lexer/builder.dart';

main(){
  group('Builder', (){
    group('rx', (){
      test('passing Languages', (){
        var lang = rx([new Character('a'), new Character('b'),
                       new Character('c')]);
        expect(lang.toString(), equals('abc'));
      });

      test('passing Strings', (){
        var lang = rx(['a', 'b', 'cdef']);
        expect(lang.toString(), equals('abcdef'));
      });

      test('passing Mixed', (){
        var lang = rx(['a', 'b', 'cdef', new Character('g')]);
        expect(lang.toString(), equals('abcdefg'));
      });
    });
  });

  group('or', (){
    test('passing Languages', (){
        var lang = or([new Character('a'), new Character('b'),
                       new Character('c')]);
        expect(lang.toString(), equals('a|b|c'));
    });
    test('passing Strings', (){
        var lang = or(['a', 'b', 'cdef']);
        expect(lang.toString(), equals('a|b|cdef'));
    });
    test('passing Mixed', (){
      var lang = or(['a', 'b', 'cdef', new Character('g')]);
      expect(lang.toString(), equals('a|b|cdef|g'));
    });
  });
  group('oneOrMore', (){
    test('passing Language', (){
      var lang = oneOrMore(new Character('a'));
      expect(lang.toString(), equals('aa*'));
    });
    test('passing String', (){
      var lang = oneOrMore('ab');
      expect(lang.toString(), equals('abab*'));
    });
  });

  group('exactly', (){
    test('passing Language', (){
      var lang = exactly(new Character('a'), times:5);
      expect(lang.toString(), equals('aaaaa'));
    });
    test('passing String', (){
      var lang = exactly('ab', times:3);
      expect(lang.toString(), equals('ababab'));
    });
  });

}
