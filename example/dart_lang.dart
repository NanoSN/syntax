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
class StringInterpolationStart extends Token {
  StringInterpolationStart([v,p]):super(v,p);
}
class StringInterpolationEnd extends Token {
  StringInterpolationEnd([v,p]):super(v,p);
}

class Comma extends Token {}    // ,
class Colon extends Token {}    // :
class SemiColon extends Token {} // ;
class Period extends Token {}    // .
class Tilde extends Token {}     // ~
class At extends Token {}        // @
class Pound extends Token {}     // #
class QuestionMark extends Token {}    // ?
class ExclamationMark extends Token {} // !

/// Block family tokens
class BlockStart extends Token {BlockStart(v,p):super(v,p);}
class BlockEnd extends Token {BlockEnd(v,p):super(v,p);}
// class OpenParen extends BlockStart {} // (
// class CloseParen extends BlockEnd {}  // )
// class OpenSquare extends BlockStart {} // [
// class CloseSquare extends BlockEnd {}  // ]
// class OpenCurly extends BlockStart {}  // {
// class CloseCurly extends BlockEnd {}   // }

abstract class Operator extends Token {}
class EqualOperator extends Operator {} // =
class GraterThan extends Operator {}    // >
class LessThan extends Operator {}      // <
class Asterisk extends Operator {}      // *
class Slash extends Operator {}         // /
class BackSlash extends Operator {}     // \
class Plus extends Operator {}          // +
class Minus extends Operator {}         // -
class Ampersand extends Operator {}     // &
class Caret extends Operator {}         // ^
class VerticalBar extends Operator {}   // |
class Percent extends Operator {}       // %

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
      this / keyword                   / () => new ReservedWord();
    }

    // Built in identifier
    for(final id in builtInIdentifiers){
      this / id                       / () => new BuiltInIdentifier();
    }

    this / IDENTIFIER                 / () => new Identifier();
    this / or([ NUMBER, HEX_NUMBER ]) / () => new Number();

    // Escape Sequences
    for(final seq in escapeSequences){
      this / seq / () => new EscapeSequence();
    }

    // Spaces.
    this / oneOrMore(or([ '\t', ' ' ])) / () => new WhiteSpace();
    this / NEWLINE                      / () => new NewLine();

    // Single line comments
    this / rx(['//', zeroOrMore(not(NEWLINE)), zeroOrOne(NEWLINE)]) /
        () => new SingleLineComment();


    this / rx([',']) / () => new Comma();
    this / rx([':']) / () => new Colon();
    this / rx([';']) / () => new SemiColon();
    this / rx(['.']) / () => new Period();
    this / rx(['~']) / () => new Tilde();
    this / rx(['@']) / () => new At();
    this / rx(['#']) / () => new Pound();
    this / rx(['?']) / () => new QuestionMark();

    /// Brackets
    State blockStart(State state, Lexer _) {
      _.emit(new BlockStart(state.matchedInput, _.position), state);
      return _.push(this);
    };
    State blockEnd(State state, Lexer _) {
      _.emit(new BlockEnd(state.matchedInput, _.position), state);
      return _.pop();
    };
    on(or([ '(', '[', '{' ])) (blockStart);
    on(or([ ')', ']', '}' ])) (blockEnd);

    /// Operators
    // TODO: should '==' be a separate token?
    this / rx(['='])  / () => new EqualOperator();
    this / rx(['>'])  / () => new GraterThan();
    this / rx(['<'])  / () => new LessThan();
    this / rx(['*'])  / () => new Asterisk();
    this / rx(['/'])  / () => new Slash();
    this / rx(['\\']) / () => new BackSlash();
    this / rx(['+'])  / () => new Plus();
    this / rx(['-'])  / () => new Minus();
    this / rx(['&'])  / () => new Ampersand();
    this / rx(['^'])  / () => new Caret();
    this / rx(['|'])  / () => new VerticalBar();
    this / rx(['%'])  / () => new Percent();
    this / rx(['!'])  / () => new ExclamationMark();

    // Multi line comments
    on('/*') << () => new Comments();

    // Strings .. let the fun begin
    on("'''")  << () => new TripleSingleQouteString();
    on('"""')  << () => new TripleDoubleQouteString();
    on("r'''") << () => new RawTripleSingleQouteString();
    on('r"""') << () => new RawTripleDoubleQouteString();

    on("'")  << () => new SingleQouteString();
    on('"')  << () => new DoubleQouteString();
    on("r'") << () => new RawSingleQouteString();
    on('r"') << () => new RawDoubleQouteString();

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
abstract class Strings extends State {
  Strings(String start, String end, {isRaw:false, isMultiline:false}){
    on(end) ( (State state, Lexer _) {
        print(">>>>>>>>>>>>>>>>>>>>>> Look here <<<<<<<<<<<<<<<<<<<<<");
        _.emit(new StringEnd(state.matchedInput,_.position), state);
        return _.pop();
    });

    var escapes = [end];
    if(!isRaw) escapes.addAll(['\\', '\$']);
    if(!isMultiline) escapes.add(NEWLINE);

    on( zeroOrMore(not(or( escapes ))) ) <=
      (State state, Lexer _) {
        if(matchedInput.startsWith(start)) {
          _.emit(new StringStart(state.matchedInput,_.position), state);
        } else {
          _.emit(new StringPart(state.matchedInput,_.position), state);
        }
        return this;
      };

    if(!isRaw) {
      this / rx([ '\\', not(NEWLINE) ]) / () => new EscapeSequence();
      this / rx([ '\$', IDENTIFIER_NO_DOLLAR ]) / () => new StringInterpolation();
      on('\${') ((State state, Lexer _) {
        _.emit(new StringInterpolationStart(state.matchedInput, _.position),
        state);
        return _.push(new Main());
      });
    }
  }
}

class SingleQouteString extends Strings {
  SingleQouteString(): super("'", "'");
}
class DoubleQouteString extends Strings {
  DoubleQouteString(): super('"', '"');
}
class RawSingleQouteString extends Strings {
  RawSingleQouteString(): super("r'", "'", isRaw:true);
}
class RawDoubleQouteString extends Strings {
  RawDoubleQouteString(): super('r"', '"', isRaw:true);
}

class TripleSingleQouteString extends Strings {
  TripleSingleQouteString(): super("'''", "'''", isMultiline:true);
}
class TripleDoubleQouteString extends Strings {
  TripleDoubleQouteString(): super('"""', '"""', isMultiline:true);
}
class RawTripleSingleQouteString extends Strings {
  RawTripleSingleQouteString(): super("r'''", "'''", isRaw:true,
                                      isMultiline:true);
}
class RawTripleDoubleQouteString extends Strings {
  RawTripleDoubleQouteString(): super('r"""', '"""', isRaw:true,
                                      isMultiline:true);
}

class DartLexer extends Lexer {
  DartLexer(stream): super(stream, new Main());
}
