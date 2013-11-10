part of lexer;

typedef void Action(Lexer context);

class Rule {
  Language language;
  Action action;

  bool get isMatch => language == match;
  bool get isReject => language == reject;
  bool get isMatchable => language.isMatchable;

  Rule([this.language, this.action]);
  Rule derive(dynamic ch) => new Rule(language.derive(ch), action);
  toString() => '$language';
}
