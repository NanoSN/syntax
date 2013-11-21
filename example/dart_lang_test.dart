import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:parse/lexer.dart';
import './dart_lang.dart';

main(){
  group('Dart Language', (){
    test('Keywords/reserved words.', (){
      String input = keywords.join(' ');
      Future<List<Token>> match = lex(input);
      expect(match, completes);

      match.then((tokens) {
        expect(tokens.length, equals(keywords.length*2-1));

        var expected = input.split(new RegExp(r'[\s\n]'));
        var actual = new List.from(tokens.where((_) => _ is ReservedWord));
        expect(actual.length, expected.length);

        //All tokens must be in the same order as input
        for(int i=0; i<expected.length; i++){
          expect(actual[i].value, equals(expected[i]));
        }
      });
    });
    test('Built in identifiers.', (){
      String input = builtInIdentifiers.join(' ');
      Future<List<Token>> match = lex(input);
      expect(match, completes);

      match.then((tokens) {
        expect(tokens.length, equals(builtInIdentifiers.length*2-1));

        var expected = builtInIdentifiers;
        var actual = new List.from(tokens.where((_) => _ is BuiltInIdentifier));
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
          var token = tokens[0];
          var actual = token is SingleLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test('at end of input (no \\n).', (){
        var input = '// This is a comment';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is SingleLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test('doc comment.', (){
        var input = '/// This is a documentation comment';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is SingleLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
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
          var token = tokens[0];
          var actual = token is MultiLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
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
          var token = tokens[0];
          var actual = token is MultiLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
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
          var token = tokens[0];
          var actual = token is MultiLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
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
          var token = tokens[0];
          var actual = token is MultiLineComment;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
    });

    group('Identifier', (){
      test('usual.', (){
        var input = 'nameing';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Identifier;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test('starts with reserved word.', (){
        var input = 'thisisaname';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Identifier;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("starts with '\$'.", (){
        var input = '\$fun';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Identifier;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("starts with '_'.", (){
        var input = '_fun';
        Future<List<Token>> match = lex(input);
        expect(match, completes);

        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Identifier;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });


      // TODO(sam): this test fails because 2 tokens are generated
      //            Number and Identifier. Is this the way it should be?
      skip_test("cannot starts with 'digit'.", (){
        var input = '1fun';
        Future<List<Token>> match = lex(input);
        expect(match, throws);
        match..catchError((error) {
          expect(error is NoMatch, isTrue);
        });
      });
    });

    group('Number', (){
      test("'1324'.", (){
        var input = '1324';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("'13.24'.", (){
        var input = '13.24';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("'1324e+10'.", (){
        var input = '1324e+10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("'1324e-10'.", (){
        var input = '1324e-10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test("'1324e10'.", (){
        var input = '1324e10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test("'13.24e+10'.", (){
        var input = '13.24e+10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });

      test("'13.24e-10'.", (){
        var input = '13.24e-10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test("'13.24e10'.", (){
        var input = '13.24e10';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test("'hex 0xAB'.", (){
        var input = '0xAB';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
      test("'hex 0XAB'.", (){
        var input = '0XAB';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          var actual = token is Number;
          expect(actual, isTrue);
          expect(token.value, equals(input));
        });
      });
    });

    group('Escape Sequence', (){
      test(r'\n \r \f \b \t \v', (){
        var input = r'\n\r\f\b\t\v';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(6));
          var value = tokens.map((_) => _.value).join('');
          var actual = tokens.every((_) => _ is EscapeSequence);
          expect(actual, isTrue);
          expect(value, equals(input));
        });
      });
    });
    group('Whitespace and Newline', (){
      test(r'\n is whitespace and newline', (){
        var input = '\n';
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          expect(tokens.length, equals(1));
          var token = tokens[0];
          expect(token is NewLine, isTrue);
          expect(token is WhiteSpace, isTrue);
          expect(token.value, equals(input));
        });
      });
    });
    group('Strings', (){
      test("single qoute.", (){
        var input = "'single qoute'";
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          print(tokens);
          expect(tokens.length, equals(2));
          expect(tokens[0] is StringStart, isTrue);
          expect(tokens[1] is StringEnd, isTrue);
        });
      });
      solo_test("\$ Interpolation.", (){
        var input = "'single \$qoute'";
        Future<List<Token>> match = lex(input);
        expect(match, completes);
        match.then((tokens) {
          print(tokens);
          expect(tokens.length, equals(2));
          expect(tokens[0] is StringStart, isTrue);
          expect(tokens[1] is StringEnd, isTrue);
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
                  _completer.completeError(_);
                },
                onDone: () => _completer.complete(result));
  return _completer.future;
}

