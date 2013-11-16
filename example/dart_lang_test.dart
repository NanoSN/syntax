import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:parse/lexer.dart';
import './dart_lang.dart';

main(){
DEBUG=true;
  group('Dart Language', (){
    test('Keywords/reserved words.', (){
      String input = '''
assert break case catch class const continue default do else enum extends false
final finally for if in is new null rethrow return super switch this throw true
try var void while with''';
      Future<List<Token>> match = lex(input);
      expect(match, completes);

      match.then((tokens) {
        expect(tokens.length, equals(65));

        var expected = input.split(new RegExp(r'[\s\n]'));
        var actual = new List.from(tokens.where((_) => _ is ReservedWord));
        expect(actual.length, expected.length);

        //All tokens must be in the same order as input
        for(int i=0; i<expected.length; i++){
          expect(actual[i].value, equals(expected[i]));
        }

      });
    });

    group('Single line comments', (){
      test('Ending with \\n.', (){
        var input = '// This is a comment \n';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is SingleLineComment;
          expect(actual, isTrue);
        });
      });

      test('at end of input (no \\n).', (){
        var input = '// This is a comment';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is SingleLineComment;
          expect(actual, isTrue);
        });
      });

      test('doc comment.', (){
        var input = '/// This is a documentation comment';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is SingleLineComment;
          expect(actual, isTrue);
        });
      });
    });

    group('Multi line comment', (){
      test('in one line.', (){
        var input = '/* This is a multi-line comment.. really */';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is MultiLineComment;
          expect(actual, isTrue);
        });
      });

      test('in multiple lines.', (){
        var input = '''/*
        This is a real multi line
        comment */''';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is MultiLineComment;
          expect(actual, isTrue);
        });
      });
      test('doc comment.', (){
        var input = '''/**
        This is a multi line doc
        comment */''';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is MultiLineComment;
          expect(actual, isTrue);
        });
      });

      test('nested.', (){
        var input = '''/*
        This is a /* multi line comment
        in a multi line comment */
        */''';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var actual = tokens[0] is MultiLineComment;
          expect(actual, isTrue);
          expect(tokens[0].value, equals(input));
        });
      });
    });
  });
}

Future<List<Token>> lex(String input){
  Completer _completer = new Completer();
  var stream = new Stream.fromIterable(input.split(''));
  var lexer = new DartLexer(stream);
  var result = new List<Token>();
  lexer.listen( (token) {
                result.add(token);},
                onError: (_) {
                  print(_);
                  _completer.completeError(_);
                },
                onDone: () => _completer.complete(result));
  return _completer.future;
}

