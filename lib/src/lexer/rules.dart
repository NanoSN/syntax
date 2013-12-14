part of lexer;

typedef void Action(State state, Lexer context);

class Rule {
  /// Pass along the root rule For debug purposes.
  Rule rootRule;

  Language language;
  Action action;

  bool get isMatch => language == match;
  bool get isReject => language == reject;
  bool get isMatchable => language.isMatchable;

  Rule([this.language, this.action, this.rootRule]);
  Rule derive(dynamic ch) {
    if(rootRule == null)
      return new Rule(language.derive(ch), action, this);
    else
      return new Rule(language.derive(ch), action, rootRule);
  }
  toString() => '{ Root:$rootRule, Language:$language }';
}
