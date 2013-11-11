import 'dart:async';
import 'package:parse/lexer.dart';

class ReservedWord extends Token {}
class WhiteSpace extends Token {}
class SingleLineComment extends Token {}
class MultiLineComment extends Token {MultiLineComment(v,p):super(v,p);}

class Init extends LexerState {}
class Comments extends LexerState {//with InternalState {}
 int internalState = 0;
  operator +(n)  {
    this..internalState += n;
    if(DEBUG) print('++ COMMENT = $internalState');
    return this;
  }
  operator -(n) {
    this..internalState -= n;
    if(DEBUG) print('-- COMMENT = $internalState');
    return this;
  }
}

var keywords = ['assert', 'break', 'case', 'catch', 'class', 'const',
                'continue', 'default', 'do', 'else', 'enum', 'extends',
                'false', 'finally', 'final', 'for', 'if', 'in', 'is', 'new',
                'null', 'rethrow', 'return', 'super', 'switch', 'this', 'throw',
                'true', 'try', 'var', 'void', 'while', 'with'];

/// States
var INIT = new Init();
var COMMENTS = new Comments();

initRules(){
  // Keywords.
  for(final k in keywords){
    INIT.on(k).emit( new ReservedWord() );
  }
  INIT
//    ..on( or(keywords) ).emit( new ReservedWord() )

    //Spaces.
    ..on( oneOrMore(or(['\t', ' ', NEWLINE])) ).emit(new WhiteSpace())

    //Single line comments
    ..on( rx(['//', zeroOrMore(not(NEWLINE)), NEWLINE]) )
      .emit(new SingleLineComment())

    //Multi line comments
    ..on('/*').switchTo(COMMENTS);
}

commentRules(){
  COMMENTS
    ..on( not('*/') ).switchTo( COMMENTS )
    ..on( '/*' ).switchTo( COMMENTS++ )
    ..on( '*/' ).call((_) {
      if(COMMENTS.internalState == 1) {
        _.emit(new MultiLineComment(_.m,_.p));
        _.currentState = INIT;
      }
      else _.currentState = COMMENTS--;
    });
}

class DartLexer extends Lexer {
  DartLexer(stream): super(INIT, stream){
    initRules();
    commentRules();
  }
}
