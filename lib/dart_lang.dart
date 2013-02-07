import 'package:parse/lex.dart';
import 'package:parse/dparser.dart';
import 'package:parse/state_machine.dart' as sm;

class Token {}
class Keyword extends Token {
  String keyword;
  Keyword(this.keyword);
  toString() => 'KW($keyword)';
}
class Identifier extends Token {
  String name;
  Identifier(this.name);
}
class Whitespace extends Token {
  String name;
  Whitespace(this.name);
}

var _ = null;

Rule reservedWords =
  (W('assert') | W('break') | W('case') | W('catch') | W('class') |W('const')
  | W('continue') | W('default') | W('do') | W('else') | W('extends')
  | W('false') | W('final') | W('finally') | W('for') | W('if') | W('in')
  | W('is') | W('new') | W('null') | W('return') | W('super') | W('switch')
  | W('this') | W('throw') | W('true') | W('try') | W('var') | W('void')
      | W('while') | W('with')) <= (_) => new Keyword(_);

Rule identifier = IDENTIFIER <= (_) => new Identifier(_);
Rule whitespace = WHITESPACE <= (_) => hidden(new Whitespace(_));

Language IDENTIFIER = IDENTIFIER_START + IDENTIFIER_PART *_ ;
Language IDENTIFIER_NO_DOLLAR = IDENTIFIER_START_NO_DOLLAR
                              + IDENTIFIER_PART_NO_DOLLAR *_ ;

Language IDENTIFIER_START = IDENTIFIER_START_NO_DOLLAR | T('\$');
Language IDENTIFIER_START_NO_DOLLAR = LETTER | T('_');
Language IDENTIFIER_PART_NO_DOLLAR =  IDENTIFIER_START_NO_DOLLAR | DIGIT;
Language IDENTIFIER_PART = IDENTIFIER_START | DIGIT;
Language LETTER = (R('a')..R('z')) | (R('A')..R('Z'));
Language DIGIT = R('0')..R('9'); // end result is an instance of CharSet
Language WHITESPACE = (T('\t') | T(' ') | NEWLINE) +_ ;
Language NEWLINE = T('\n') | T('\r');
Language RESERVED_WORDS =
  (W('assert') | W('break') | W('case') | W('catch') | W('class') |W('const')
      | W('continue') | W('default') | W('do') | W('else') | W('extends')
      | W('false') | W('final') | W('finally') | W('for') | W('if') | W('in')
      | W('is') | W('new') | W('null') | W('return') | W('super') | W('switch')
      | W('this') | W('throw') | W('true') | W('try') | W('var') | W('void')
      | W('while') | W('with'));

class DartLexer extends sm.StatefullState {
  var main = new sm.State();
  
  void Rules(){
    main >> ( IDENTIFIER <= (_) => new Identifier(_) )
         >> ( WHITESPACE <= (_) => hidden(new Whitespace(_)) )
         >> ( RESERVED_WORDS <= (_) => new Keyword(_) );
  }
}


//Parser simpleVar = W('var') + identifier + T(';'); // var me;


main() {
  String s = 'var bla;';

  var expected = ['KW(var)', 'ID(bla)'];

  var rules = [reservedWords]; //, whitespace, identifier];
  var o = new Lexer(rules)..lex(s);
  print(o.out);


}

/*
  1. split chars into tokens "var bla;" => W('var') Id('bla') 
 */
