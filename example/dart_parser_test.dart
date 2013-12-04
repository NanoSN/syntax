import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:syntax/parser.dart';

import './dart_parser.dart';
import './dart_lang.dart';


main(){
  group('Dart Parser', (){
    test('Variable Declaration', (){
      var input = 'var bla';
      var parser = variableDeclaration();
      Future<List<Token>> match = lex(input);
      expect(match, completes);
      match.then((tokens) {
        for(final token in tokens){
          parser = parser.derive(token);
        }
        expect(parser.isMatchable, isTrue);
        expect(parser.toAst()[0] is VariableDeclaration, isTrue);
      });
    });

    skip_test('Declared Identifier', (){
      var input = '@Bla var bla;';
      var parser = topLevelDefinition();
        //topLevelDefinition();//declaredIdentifier();

      Future<List<Token>> match = lex(input);
      expect(match, completes);
      match.then((tokens) {
       for(final token in tokens){
         parser = parser.derive(token);
         print(token);
         print(parser.toAst());
       }
       print(parser.toAst());
      });
    });
  });
}

Future<List<Token>> lex(String input){
  Completer _completer = new Completer();
  var stream = new Stream.fromIterable(input.split(''));
  var lexer = new DartLexer(stream);
  var result = new List<Token>();
  lexer.where((_) => _ is! WhiteSpace)
       .listen( (token) {
                result.add(token);},
                onError: (_) {
                  _completer.completeError(_);
                },
                onDone: () => _completer.complete(result));
  return _completer.future;
}
