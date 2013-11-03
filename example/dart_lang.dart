import 'dart:async';
import 'package:parse/lexer.dart';


class Keyword extends Token {
  final String keyword;
  Keyword(this.keyword);
  toString() => 'Keyword: $keyword';
}


Rule keywordRule = new Rule(rx([or(['if', 'else'])]),
                       (_) => new Keyword(_));
Rule spacesRule = new Rule(rx([oneOrMore(' ')]), (_) => 'SPACE');


main() {
  var data = 'if    else  if else'.split('');
  var stream = new Stream.fromIterable(data);  // create the stream

  var rules = [keywordRule, spacesRule];

  var lexer = new Lexer(rules, stream);
  lexer.listen((v)=> print(v));
}
