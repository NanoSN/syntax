
import 'package:unittest/unittest.dart';
import 'package:parse/parser.dart';


Token T(String token) => new Token(token);
RegEx R(String pattern) => new RegEx(pattern);
void main(){
  var parser = new And(T('product'), T('add'));
  var p2 = T('product') + T('add') + T('task') + R(r'\w') + T('wohoo');
  
  var tokens = ['product', 'add', 'task', 'fundskljalfkj', 'wohoo'];

  //print(T('product').derive('product').parseNull());
  var s = p2.parse(tokens);
  print(s.length);
  print(s);
}
