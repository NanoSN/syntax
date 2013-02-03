
import 'package:parse/lex.dart';

C(s) => new Character(s);

main(){
  var regex = C('s').and(C('a'));
  print(regex);
  for(final c in 'sa'.splitChars()){
    regex = regex.derive(c);
    print(regex);
    print(regex.acceptsEmptyString);
    print(regex.rejectsAll);
    print(regex.isEmptyString);
    print('\n');
  }

  print('---');
  regex = C('s').and(C('a'));
  for(final c in 'smsam'.splitChars()){
    regex = regex.derive(c);
    print(regex);
    print(regex.acceptsEmptyString);
    print(regex.rejectsAll);
    print(regex.isEmptyString);
    print('\n');
  }
}
