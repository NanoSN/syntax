part of lexer;

class Rule {
  final Language language;
  final Function action;

  bool get isMatch => language == match;
  bool get isReject => language == reject;
  bool get isMatchable => language.isMatchable;

  Rule(this.language, this.action);
  Rule derive(dynamic ch) => new Rule(language.derive(ch), action);
  toString() => '$language';
}
