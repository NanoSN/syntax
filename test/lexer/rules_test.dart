
import 'package:unittest/unittest.dart';
import 'package:parse/lexer.dart';

main(){
  group('Rule', (){
    test('derive', (){
      var lang = rx(['if', 'else']);
      var action = () => print('yay');
      var rule = new Rule(lang, action);
      rule = rule.derive('i');
      expect(rule.language.toString(), equals(lang.derive('i').toString()));
      expect(rule.action, equals(action));
    });
  });
  m();
}

m() {
  var ifRule = new Rule(rx([or(['if', 'else']), EOI]), (_) => print(_));
  var derivative = ifRule;
  var str = 'if else';
  var matchStr = '';
  for(int i=0; i< str.length; i++){
    matchStr += str[i];
    derivative = derivative.derive(str[i]);
    if(derivative.derive(EOI).isMatch){
      ifRule.action(matchStr);
      //reset
      derivative = ifRule;
      matchStr = '';
    }
  }
}
