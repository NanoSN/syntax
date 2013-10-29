
import 'package:parse/lexer.dart';

class Token {}
class Keyword extends Token {
  final String keyword;
  Keyword(this.keyword);
  toString() => 'Keyword: $keyword';
}


Rule keywordRule = new Rule(rx([or(['if', 'else'])]),
                            (_) => print(new Keyword(_)));

Rule spacesRule = new Rule(rx([oneOrMore(' ')]), (_) => print('SPACE'));
main() {
  var rules = [keywordRule, spacesRule];
  var ds = rules;
  var str = 'if    else  ';
  var matchStr = '';

  var lastMatch = null;
  var lastMatchStr = null;
  var reset = false;

  for(int i=0; i< str.length; i++){
    matchStr += str[i];
    if(lastMatch == null){
      ds = ds.map((_) => _.derive(str[i])).where((_) => !_.isReject);

      if(exactMatchDispatched(ds, matchStr)){
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

bool exactMatchDispatched(List<Rule> rules, String matched){
  var matches = rules.where((_) => _.isMatch);
  if(matches.length > 1) throw "More that one match is not supported yet";
  if (matches.length == 1){
    matches.first.action(matched);
    return true;
  }
  return false;
}
