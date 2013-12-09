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
        //expect(parser.toAst()[0] is VariableDeclaration, isTrue);
      });
    });


    test("Qualified 'foo'", (){
      var input = 'foo';
      var parser = qualified();
      Future<List<Token>> match = lex(input);
      expect(match, completes);
      match.then((tokens) {
        for(final token in tokens){
          parser = parser.derive(token);
        }
        expect(parser.isMatchable, isTrue);
        expect(parser.toAst()[0] is AstNode, isTrue);
      });
    });

    test("Qualified 'foo.bar'", (){
      var input = 'foo.bar';
      var parser = qualified();
      Future<List<Token>> match = lex(input);
      expect(match, completes);
      match.then((tokens) {
        for(final token in tokens){
          parser = parser.derive(token);
        }
        expect(parser.isMatchable, isTrue);
        expect(parser.toAst()[0] is AstNode, isTrue);
      });
    });

    test("Metadata is optional", (){
      var parser = metadata();
      expect(parser.isMatchable, isTrue);
    });

    skip_test("Metadata '@Foo'", (){
      var input = '@Foo.bar.foo';
      var parser = metadata();
      print(parser.toReadableString());
      Future<List<Token>> match = lex(input);
      expect(match, completes);
      match.then((tokens) {
        print(tokens);
        for(final token in tokens){
          parser = parser.derive(token);
        }
        expect(parser.isMatchable, isTrue);
        expect(parser.toAst()[0] is AstNode, isTrue);
      });
    });

    skip_test('Dart Application', (){
      var input = 'var bla;';
      var parser = dartProgram(); //topLevelDefinition();
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
