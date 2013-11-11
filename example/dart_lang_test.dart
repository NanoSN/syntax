import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:parse/lexer.dart';
import './dart_lang.dart';

main(){
//  DEBUG=true;
  group('Dart Language', (){
    test('Keywords/reserved words', (){
      String input = '''
assert break case catch class const continue default do else enum extends false
final finally for if in is new null rethrow return super switch this throw true
try var void while with''';
      Future<List<Token>> match = lex(input);
      expect(match, completes);

      match.then((tokens) {
        expect(tokens.length, equals(65));
        var actual = input.split(new RegExp(r'[\s\n]')).length;
        var expected = tokens.where((_) => _ is ReservedWord).length;
        expect(expected, actual);
      });
    });
  });
}


Future<List<Token>> lex(String input){
  Completer _completer = new Completer();
  var stream = new Stream.fromIterable(input.split(''));
  var lexer = new DartLexer(stream);
  var result = new List<Token>();
  lexer.listen( (token) {result.add(token);},
                onError: (_) => _completer.completeError(_),
                onDone: () => _completer.complete(result));
  return _completer.future;
}

Future<Token> isMatch(Rule rule, String input){
  Completer _completer = new Completer();
  var stream = new Stream.fromIterable(input.split(''));
  var lexer = new Lexer([rule], stream);
  lexer.listen((v)=> _completer.complete(v),
                     onError: (_)=> _completer.completeError(_));
  return _completer.future;
}
