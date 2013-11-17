import 'package:parse/lexer.dart';

class ReservedWord extends Token {}
class BuiltInIdentifier extends Token {}
class WhiteSpace extends Token {}
class SingleLineComment extends Token {}
class MultiLineComment extends Token {MultiLineComment(v,p):super(v,p);}

class Identifier extends Token {}
class Number extends Token {}

List<String> keywords = ['assert', 'break', 'case', 'catch', 'class', 'const',
                'continue', 'default', 'do', 'else', 'enum', 'extends',
                'false', 'finally', 'final', 'for', 'if', 'in', 'is', 'new',
                'null', 'rethrow', 'return', 'super', 'switch', 'this', 'throw',
                'true', 'try', 'var', 'void', 'while', 'with'];

List<String> builtInIdentifiers = [
    'abstract', 'as', 'dynamic', 'export', 'external ', 'factory', 'get',
    'implements', 'import', 'library', 'operator', 'part', 'set', 'static',
    'typedef'];


Language IDENTIFIER = and([ IDENTIFIER_START, zeroOrMore(IDENTIFIER_PART) ]);

Language IDENTIFIER_START = or([ IDENTIFIER_START_NO_DOLLAR, '\$' ]);
Language IDENTIFIER_START_NO_DOLLAR = or([ LETTER, '_' ]);
Language IDENTIFIER_PART = or([ IDENTIFIER_START, DIGIT ]);
Language IDENTIFIER_PART_NO_DOLLAR = or([ IDENTIFIER_START_NO_DOLLAR, DIGIT ]);
Language IDENTIFIER_NO_DOLLAR = and( [ IDENTIFIER_START_NO_DOLLAR,
                                      zeroOrMore(IDENTIFIER_PART_NO_DOLLAR) ]);


/**
NUMBER:
     DIGIT+ ('.' DIGIT+)? EXPONENT?
   |  '.' DIGIT+ EXPONENT?
   ;
*/
Language EXPONENT =  and([ or([ 'e', 'E' ]),  optional(or([ '+', '-' ])),
                          oneOrMore(DIGIT)]);

Language NUMBER = or([ and([ oneOrMore(DIGIT),
                             optional( and([ '.', oneOrMore(DIGIT) ]) ),
                             optional(EXPONENT) ]),
                       and([ '.', oneOrMore(DIGIT), optional(EXPONENT) ]) ]);

/**
HEX_NUMBER:
     '0x' HEX_DIGIT+
   | '0X' HEX_DIGIT+
   ;
*/
Language HEX_NUMBER = or([ and([ '0x', oneOrMore(HEX_DIGIT) ]),
                           and([ '0X', oneOrMore(HEX_DIGIT) ]) ]);



/**
ESCAPE_SEQUENCE:
     ‘\n’
   | ‘\r’
   | ‘\f’
   | ‘\b’
   | ‘\t’
   | ‘\v’
   | “\x’ HEX_DIGIT HEX_DIGIT
   | ‘\u’ HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
   | ‘\u{‘ HEX_DIGIT_SEQUENCE ‘}’
*/


class Main extends State {
  Main(){

    // Keywords.
    for(final keyword in keywords){
      this / keyword / () => new ReservedWord();
    }

    // Built in identifier
    for(final id in builtInIdentifiers){
      this / id / () => new BuiltInIdentifier();
    }

    this / IDENTIFIER / () => new Identifier();

    this / or([ NUMBER, HEX_NUMBER ]) / () => new Number();

    // Spaces.
    this / oneOrMore(or(['\t', ' ', NEWLINE])) / () => new WhiteSpace();

    // Single line comments
    this / rx(['//', zeroOrMore(not(NEWLINE)), zeroOrOne(NEWLINE)]) /
        () => new SingleLineComment();

    // Multi line comments
    on('/*') <= () => new Comments();

  }
}

/// When getting into this state, the first /* has already been parsed.
class Comments extends State {
 int internalState = 0;
  operator +(n) => this..internalState += n;
  operator -(n) => this..internalState -= n;

  Comments(){
    on( '/*' )      <= () => this..internalState+=1;
    on( not('*/') ) <= this;
    on( '*/' )      <= (State state, Lexer _) {
      if(internalState == 0) {
        _.emit(new MultiLineComment(state.matchedInput,_.position));
        return new Main();
      } else {
        internalState--;
        return this;
      }
    };
  }
}

/// State when we are in Strings
class Strings extends State {

}

class DartLexer extends Lexer {
  DartLexer(stream): super(stream, new Main());
}
