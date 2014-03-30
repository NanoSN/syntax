library syntax;

import 'dart:async';
import 'dart:mirrors';

import 'token.dart';
export 'token.dart';
import 'parser.dart' as p;
import 'lexer.dart' as l;

part 'src/syntax/builder.dart';

/**
  - each lexer language will produce a token. Need a way to define this.
*/

LanguageRuleBuilder DIGIT = new LanguageRuleBuilder(l.DIGIT);

class Syntax {
  Stream input;
  l.Lexer lexer;
  p.Parser parser;
  Syntax(this.input, this.parser){
    lexer = new l.Lexer(input);
    for(final s in lex_string_rules.toSet()){
      lexer.INIT / s / () => new Token();
    }
    lexer.INIT.rules.addAll(lex_language_rules.toSet());
    lexer.listen( (token) {
      print(token);
      parser = parser.derive(token);},
      onDone: () => print(parser.toAst()));
  }
}
