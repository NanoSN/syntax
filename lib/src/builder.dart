/// Helper functions for building [Language].

part of lexer;


/// Main entry for the builder.
Language rx(List<dynamic> languages){
  var result = toLanguage(languages.first);
  for(int i=1; i< languages.length; i++){
    result = new And(result, toLanguage(languages[i]));
  }
  return result;
}


Language or(List<dynamic> languages){
  var result = toLanguage(languages.first);
  for(int i=1; i< languages.length; i++){
    result = new Or(result, toLanguage(languages[i]));
  }
  return result;
}


Language oneOrMore(dynamic language) => new And(toLanguage(language),
                                                new Star(toLanguage(language)));
Language zeroOrMore(dynamic language) => new Star(toLanguage(language));
Language exactly(dynamic language, {int times:1}){
  language = toLanguage(language);
  var result = language;
  for(int i = 1; i < times; i++){
    result = new And(result, language);
  }
  return result;
}


/// Try to convert anything to [Language].
Language toLanguage(dynamic thing){
  if(thing is String) return word(thing);
  if(thing is Language) return thing;
  throw 'Unknown type of language: [$thing]';
}


/// Converts a [String] into a [Language].
Language word(String str){
  if(str.length == 0) throw 'String is empty.';
  if(str.length == 1) return new Character(str);
  var result = new Character(str[0]);
  for(int i=1; i< str.length; i++){
    result = new And(result, new Character(str[i]));
  }
  return result;
}

Language letter = new Letter();
Language digit = new Digit();
