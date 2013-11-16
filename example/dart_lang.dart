import 'package:parse/lexer.dart';

class ReservedWord extends Token {}
class WhiteSpace extends Token {}
class SingleLineComment extends Token {}
class MultiLineComment extends Token {MultiLineComment(v,p):super(v,p);}


var keywords = ['assert', 'break', 'case', 'catch', 'class', 'const',
                'continue', 'default', 'do', 'else', 'enum', 'extends',
                'false', 'finally', 'final', 'for', 'if', 'in', 'is', 'new',
                'null', 'rethrow', 'return', 'super', 'switch', 'this', 'throw',
                'true', 'try', 'var', 'void', 'while', 'with'];


class Main extends State {
  Main(){

    // Keywords.
    for(final keyword in keywords){
      this / keyword / () => new ReservedWord();
    }

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

class DartLexer extends Lexer {
  DartLexer(stream): super(stream, new Main());
}
