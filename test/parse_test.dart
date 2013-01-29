
import 'package:unittest/unittest.dart';
import 'package:parse/parser.dart';


Token T(String token) => new Token(token);
void main(){
  
    test('Token parser', (){
      var t = T('t');
      var d = t.derive('t');
      expect(d is Null, isTrue);
      expect(d.parseNull(), equals(['t']));
    });
    test('Empty parser', (){
      var e = new Empty();
      expect(e.derive('') is Empty, isTrue);
      expect(e.parseNull(), equals([]));
    });

    test('And Parser', (){
      var and = new And(T('a'), T('b'));
      print(and.parse(['a', 'b']));
    });
    
    test('equality', (){
      var r = 1 == false; print('1 == false; // $r');
      r = 1 == true; print('1 == true; // $r');

      r = 1 == '1'; print('1 == "1"; // $r');
      r = '1' == '1'; print("'1' == '1'; // $r");

      r = 'str' == true; print("'str' == true; // $r");
      r = 'str' == false; print("'str' == false; // $r");


      
      r = [] == true; print("[] == true; // $r");
      r = [] == true; print("[] == false; // $r");

      
      r = 'str' == 'str'; print("'str' == 'str'; // $r");
      r = identical('str','str'); print("identical('str','str'); // $r");

      r = 'str' == 'str'.toString(); print("'str' == 'str'.toString(); // $r");
      r = identical('str','str'.toString()); print("identical('str','str'.toString()); // $r");

      r = 'str' == 'str '.trim(); print("'str' == 'str '.trim(); // $r");
      r = identical('str','str '.trim()); print("identical('str','str '.trim()); // $r");

      
      r = 'str '.trim() == 'str '.trim(); print("'str '.trim() == 'str '.trim(); // $r");
      r = identical('str '.trim(), 'str '.trim()); print("identical('str '.trim(), 'str '.trim()) // $r");

      r = 'str '.substring(1) == 'str '.substring(1); 
      print("'str '.substring(1) == 'str '.substring(1); // $r");
      
      r = identical('str '.substring(1), 'str '.substring(1)); 
      print("identical('str '.substring(1), 'str '.substring(1)); // $r");      
      
      r = 'str'.splitChars() == 'str'.splitChars();
      print("'str'.splitChars() == 'str'.splitChars(); // $r");
      
      r = new Date(2012) == new Date(2012);
      print("new Date(2012) == new Date(2012); // $r");
      
      r = identical(new Date(2012), new Date(2012));
      print("identical(new Date(2012), new Date(2012)); // $r");
      
      r = new Me() == new Me(); // should throw noSuchMethodError
      print("new Me() == new Me(); // $r");
      
      r = new You() == new Me();
      print("new You() == new Me(); // $r");
      
      r = identical(new You(), new Me());
      print("identical(new You(), new Me()); // $r");

      //r = new NotMe() == new NotMe();
      print("new NotMe() == new NotMe(); // $r");

      var notme = new NotMe();
      //r = notme == notme;
      //print("notme == notme; // $r");
      
      r = identical(notme, notme);
      print("identical(notme, notme); // $r");
      
      r = notme == null;
      print("notme == null; // $r");
    });
    
    
    test('string', (){
      var foo = new Foo();
      var r = foo == foo; print('foo == foo; // $r');
      r = identical(foo, foo);print('identical(foo, foo); // $r');
    });
}
class Foo{operator ==(o) => false;}
class Me{}
class You{operator==(other) => true;}
class NotMe{operator==(other) => throw new NoSuchMethodError(this, '==', [], {});}
