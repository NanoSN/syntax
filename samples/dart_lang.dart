
import 'package:parse/lexer/language.dart';
import 'package:parse/lexer/builder.dart';
import 'package:parse/lexer/rules.dart';

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
  var derivatives = rules;
  var str = 'if    else';
  var matchStr = '';

  var lastMatch = null;
  var lastMatchStr = null;
  var reset = false;

  for(int i=0; i< str.length; i++){
    var d = derivatives.first;
    if(d.isMatch){
      d.action(matchStr);
      reset = true;
    }
    if(reset){
      derivatives = rules;
      lastMatch = null;
      lastMatchStr = null;
      reset = false;
    }

    print(str[i]);
    matchStr += str[i];
    derivatives = derivatives.map((_) => _.derive(str[i])).where((_) => !_.rejects);
    print(new List.from(derivatives));

    if(derivatives.length == 0) break; //  Reject it all.
    if(derivatives.length != 1) continue;

    if(d.derive(EOI).isMatch){  // We got a match
      lastMatch = d;
      lastMatchStr = matchStr;
    } else if (lastMatch != null){  // We got an old match
      lastMatch.action(lastMatchStr);
      reset = true;
    }
    print(reset);

  } //End of for loop
}
    // if(derivatives.length == 1 && derivatives.first.derive(EOI).isMatch){
    //   derivatives.first.action(matchStr);
    //   //reset
    //   derivatives = rules;
    //   matchStr = '';
    // }

    // if(derivatives.length == 1){ // We kinda have a match
    //   if(derivatives.first.derive(EOI).isMatch){ //We have a match
    //     print('match [$matchStr]');
    //     lastMatchStr = matchStr;
    //     lastMatch = derivatives.first;
    //   } else {
    //     print('no match [$matchStr]');
    //     if(lastMatch != null){
    //       lastMatch.action(lastMatchStr);

    //       //reset
    //       derivatives = rules;
    //       matchStr = '';
    //       lastMatch = null;
    //       lastMatchStr = null;
    //     }
    //   }
    // } else if (lastMatch != null){
    //     lastMatch.action(lastMatchStr);
    //     //reset
    //     derivatives = rules;
    //     matchStr = '';
    //     lastMatch = null;
    //     lastMatchStr = null;
    //   }
