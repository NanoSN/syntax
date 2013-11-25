
import 'package:unittest/unittest.dart';
import 'package:syntax/lexer.dart';

main(){
  group('Rule', (){
    test('derive', (){
      var lang = rx(['if', 'else']);
      var action = () {};
      var rule = new Rule(lang, action);
      rule = rule.derive('i');
      expect(rule.language.toString(), equals(lang.derive('i').toString()));
      expect(rule.action, equals(action));
    });
  });
}
