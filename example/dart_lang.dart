import 'dart:async';
import 'package:parse/lexer2.dart';

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

var INIT = new Init();
var COMMENTS = new Comments();

initRules(){
  INIT
    // Keywords.
    ..on( or(['if', 'else']) ).emit( new ReservedWord() )

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


main(){
 // DEBUG = true;
  initRules();
  commentRules();

  var data = """
  if
/* else
lkjdfakls jdklsa jlkdfs jfdlsk jfskladj lkfsjd
*/ else  """.split('');
  var stream = new Stream.fromIterable(data);  // create the stream
//  var rules = [reservedWords, spacesRule];
  var lexer = new Lexer(INIT, stream);
  lexer.listen((v)=> print(v));
}
