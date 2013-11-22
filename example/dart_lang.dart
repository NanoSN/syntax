import 'package:syntax/lexer.dart';

class ReservedWord extends Token {}
class BuiltInIdentifier extends Token {}

/// Parser needs to distinguish between NEWLINE and WHITESPACE
class WhiteSpace extends Token {}
class NewLine extends WhiteSpace {}

class SingleLineComment extends Token {}
class MultiLineComment extends Token {MultiLineComment(v,p):super(v,p);}

class Identifier extends Token {}
class Number extends Token {}
class EscapeSequence extends Token {}

class StringStart extends Token {StringStart(v,p):super(v,p);}
class StringPart extends Token {StringPart(v,p):super(v,p);}
class StringEnd extends Token {StringEnd(v,p):super(v,p);}
class StringInterpolation extends Token {StringInterpolation([v,p]):super(v,p);}

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
List escapeSequences = [
    r'\n',
    r'\r',
    r'\f',
    r'\b',
    r'\t',
    r'\v',
    and([ r'\x', HEX_DIGIT, HEX_DIGIT ]),
    and([ r'\u', HEX_DIGIT, HEX_DIGIT, HEX_DIGIT, HEX_DIGIT]),
    and([ r'\u{', HEX_DIGIT_SEQUENCE, '}' ])
];

Language HEX_DIGIT_SEQUENCE = and([
    HEX_DIGIT, optional(HEX_DIGIT), optional(HEX_DIGIT),
    optional(HEX_DIGIT), optional(HEX_DIGIT), optional(HEX_DIGIT) ]);

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

    // Escape Sequences
    for(final seq in escapeSequences){
      this / seq / () => new EscapeSequence();
    }

    // Spaces.
    this / oneOrMore(or([ '\t', ' ' ])) / () => new WhiteSpace();
    this / NEWLINE / () => new NewLine();

    // Single line comments
    this / rx(['//', zeroOrMore(not(NEWLINE)), zeroOrOne(NEWLINE)]) /
        () => new SingleLineComment();

    // Multi line comments
    on('/*') << () => new Comments();

    // Strings .. let the fun begin
    on("'") << () => new SingleQouteString();

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
        _.emit(new MultiLineComment(state.matchedInput,_.position), state);
        return _.pop();
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

/**
string = 'foo $bar bla'
tokens = StringOpen('foo ) Token($) Identifier(bar) StringClose( bla')

string = 'foo $bar $bla'
tokens = StringOpen('foo ) Token($) Identifier(bar) StringPart( ) Token($)
         Identifier(bla) StringClose(')

string = 'foo ${foo.bar} bla'
tokens = StringOpen('foo ) Token(${) ID(foo) Token(.) ID(bar) Token(})
         StringClose( bla')
*/
class SingleQouteString extends Strings {
  SingleQouteString(){

    on("'") <= (State state, Lexer _) {
        _.emit(new StringEnd(state.matchedInput,_.position), state);
        return _.pop();
    };

    //this / not( or([ '\\', "'", '\$', NEWLINE ])) /
    on( zeroOrMore(not(or([ '\\', "'", '\$', NEWLINE ])))) <=
        (State state, Lexer _) {
          if(matchedInput.startsWith("'")) {
            _.emit(new StringStart(state.matchedInput,_.position), state);
          } else {
            _.emit(new StringPart(state.matchedInput,_.position), state);
          }
          return this;
        };

    // Escape Sequences
    for(final seq in escapeSequences){
      this / seq / () => new EscapeSequence();
    }

    this / rx([ '\\', not(NEWLINE) ]) / () => new EscapeSequence();
    this / rx([ '\$', IDENTIFIER_NO_DOLLAR ]) / () => new StringInterpolation();
    on('\${') << () => new StringInterpolationState();

  }
}

class StringInterpolationState extends State {
  StringInterpolationState(){
    on( '{' )       <= () => new StringInterpolationState();
    this / ( zeroOrMore(not('}')) ) / () => new StringInterpolation();
    on( '}' )      <= (State state, Lexer _) {
        _.emit(new StringInterpolation(state.matchedInput,_.position), state);
        return _.pop();
    };
  }
}
class DartLexer extends Lexer {
  DartLexer(stream): super(stream, new Main());
}
