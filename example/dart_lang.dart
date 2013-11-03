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
working_main() {
  var rules = [keywordRule, spacesRule];
  var ds = rules;
  var str = 'if    else  ';
  var matchStr = '';

  var lastMatch = null;
  var lastMatchStr = null;

  for(int i=0; i< str.length; i++){
    matchStr += str[i];
    if(lastMatch == null){
      ds = ds.map((_) => _.derive(str[i])).where((_) => !_.isReject);
      if(isExactMatch(ds)){
        dispatch(ds, matchStr);

        //reset
        matchStr = '';
        ds = rules;
        continue;
      }

      var matchables = ds.where((_) => _.isMatchable);
      if(matchables.length > 1) throw "More that one matchable not supported yet";
      if(matchables.length == 1) {
        lastMatch = matchables.first;
        lastMatchStr = matchStr;
      }
    } else { //We have lastMatch

      if(lastMatch.derive(str[i]).isMatchable){ // or .isMatchable
        lastMatch = lastMatch.derive(str[i]);
        lastMatchStr = matchStr;
      } else {
        lastMatch.action(lastMatchStr);
        //clean up
        lastMatch = null;
        lastMatchStr = null;
        matchStr = str[i];
        ds = rules.map((_) => _.derive(str[i])).where((_) => !_.isReject);
      }
    }
  } //End of for loop

  if(lastMatch != null)
    lastMatch.action(lastMatchStr);
}

bool isExactMatch(List<Rule> rules){
  var matches = rules.where((_) => _.isMatch);
  if(matches.length > 1) throw "More that one match is not supported yet";
  return matches.length == 1;
}

void dispatch(rules, matched){
  rules.where((_) => _.isMatch).first.action(matched);
}


/// Using streams
streamMain(){
  var data = 'if    else  '.split('');
  var stream = new Stream.fromIterable(data);  // create the stream

  var rules = [keywordRule, spacesRule];

  var state = new MState(rules, '', null, null);

  // subscribe to the streams events
  stream.listen(
  (ch) {
    try{
      state = state.derive(ch);
      new ExactMatch(state).doWork();
      new Matchable(state).doWork();

    } on Dispatched {
      state = new MState(rules, '', null, null);
    } on LastMatchDispatched {
      state = new MState(rules, '', null, null).derive(ch);
    }
  },
  onDone:()=> state.dispatchLastMatch());
}

class MState {
  String matchStr;
  String lastMatchStr;
  Rule lastMatch;
  final List<Rule> rules;
  MState(this.rules, this.matchStr, this.lastMatchStr, this.lastMatch);

  MState derive(ch){
    if(lastMatch != null){
      return deriveLastMatch(ch);
    }
    return deriveRules(ch);
  }

  MState deriveRules(ch) {
    matchStr += ch;
    return new MState(rules.map((_) => _.derive(ch)).where((_) => !_.isReject),
        this.matchStr, this.lastMatchStr, this.lastMatch);
  }

  MState deriveLastMatch(ch){
    var ds = lastMatch.derive(ch);
    if(ds.isMatchable){
      return new MState(rules, matchStr, matchStr, ds);
    }
    ds.action(lastMatch);
    throw new LastMatchDispatched();
  }


  List<Rule> findExactMatches() => rules.where((_) => _.isMatch);
  List<Rule> findPossibleMatches() => rules.where((_) => _.isMatchable);
  void dispatch() => rules.first.action(matchStr);
  void dispatchLastMatch() {
    if(lastMatch != null){
      lastMatch.action(lastMatchStr);
    }
  }
}

abstract class Worker {
  final MState state;
  Worker(this.state);
  void doWork();
}


class ExactMatch extends Worker {
  ExactMatch(state): super(state);

  doWork(){
    if(state.lastMatch != null) return;
    var matches = state.findExactMatches();
    if(matches.length > 1) throw "More that one match is not supported yet";
    if(matches.length == 1) {
      state.dispatch();
      throw new Dispatched();
    }
  }
}

class Matchable extends Worker {
  Matchable(state): super(state);

  doWork(){
    if(state.lastMatch != null) return;
    var matchables = state.findPossibleMatches();
    if(matchables.length > 1) throw "More that one matchable not supported yet";
    if(matchables.length == 1) {
      state.lastMatch = matchables.first;
      state.lastMatchStr = state.matchStr; //TODO: set this through lastMatch.
    }
  }
}

class Dispatched{}
class LastMatchDispatched{}


//main() => streamMain();

main() {
  var data = 'if    else  if else'.split('');
  var stream = new Stream.fromIterable(data);  // create the stream

  var rules = [keywordRule, spacesRule];

  var lexer = new Lexer(rules, stream);
  lexer.listen((v)=> print(v));
}
