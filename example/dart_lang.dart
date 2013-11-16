import 'package:parse/lexer.dart';

class ReservedWord extends Token {}
class WhiteSpace extends Token {}
class SingleLineComment extends Token {}
class MultiLineComment extends Token {MultiLineComment(v,p):super(v,p);}

class Init extends State {}
class Comments extends State {//with InternalState {}
 int internalState = 0;
  operator +(n)  {
    this..internalState += n;
//    print('++ COMMENT = $internalState : $rules');
    return this;
  }
  operator -(n) {
    this..internalState -= n;
//    print('-- COMMENT = $internalState: $rules');
    return this;
  }
}

var keywords = ['assert', 'break', 'case', 'catch', 'class', 'const',
                'continue', 'default', 'do', 'else', 'enum', 'extends',
                'false', 'finally', 'final', 'for', 'if', 'in', 'is', 'new',
                'null', 'rethrow', 'return', 'super', 'switch', 'this', 'throw',
                'true', 'try', 'var', 'void', 'while', 'with'];


class DartLexer extends Lexer {
  /// States
  var INIT = new Init();
  var COMMENTS = new Comments();

  Lexer lexer;

  DartLexer(stream): super(stream){
    initRules();
    commentRules();
  }
  initRules(){
    // Keywords.
    for(final k in keywords){
      //    INIT.on(k).emit( () => new ReservedWord() );
//      INIT.on(k) <= () => new ReservedWord();
      INIT << k >> () => new ReservedWord();
      //    INIT / rule / action;
    }

    //Spaces.
    INIT << oneOrMore(or(['\t', ' ', NEWLINE])) >> () => new WhiteSpace();
    //Single line comments
    INIT << rx(['//', zeroOrMore(not(NEWLINE)), zeroOrOne(NEWLINE)])
      >> () => new SingleLineComment();

    //Multi line comments
    INIT.on('/*').switchTo(() => COMMENTS++);
  }

  commentRules(){
    COMMENTS..on( '/*' ).switchTo( () => COMMENTS++ )// this is my problem
            ..on( not('*/') ).switchTo( COMMENTS )
            ..on( '*/' ).call((state, _) {
              // print('------------------');
              // print(state);
              // print('==========================================');
              //print('COMMENT: ${COMMENTS.internalState}');
              if(COMMENTS.internalState == 1) {
                _.emit(new MultiLineComment(state.matchedInput,_.position));
                //_.currentState = INIT;
                return INIT;
              }
              else {
                //_.currentState = COMMENTS--;
                COMMENTS--;
                return COMMENTS..matchedInput = state.matchedInput;
              }
            });
  }
}
