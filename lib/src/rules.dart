part of lexer;

class Rule {
  final Language language;
  final Function action;
  Rule(this.language, this.action);

  bool get accepts => language.canAccept;
  bool get isMatch => language.isMatch;
  bool get rejects => language.isReject;
  Rule derive(dynamic ch) => new Rule(language.derive(ch), action);
  toString() => '$language';
}

class State {
  final List<Rule> rules;
  State(this.rules);
  State derive(c) =>
      new State(rules.map((_) => _.derive(c)).where((_) => !_.rejects));
}
