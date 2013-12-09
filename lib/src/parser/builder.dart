/// Parser Expression builder.

part of parser;

/// Main entry for the builder.
Parser px(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = makeAnd(result, toParser(parsers[i]));
  }
  return result;
}


Parser or(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = makeOr(result, toParser(parsers[i]));
  }
  return result;
}

Parser and(List<dynamic> parsers) => px(parsers);
Parser oneOrMore(dynamic parser) => makeAnd(toParser(parser),
    makeStar(toParser(parser)));
Parser zeroOrMore(dynamic parser) => makeStar(toParser(parser));
Parser zeroOrOne(dynamic parser) => makeOptional(toParser(parser));
Parser optional(dynamic parser) => zeroOrOne(parser);


Map<String, Parser> cache = <String,Parser>{};
List<String> _inCall = <String>[];
/// Try to convert anything to [Parser].
Parser toParser(dynamic thing, [name]){
  bool hasName = (name != null);
  if(thing is Function){
    var name = reflect(thing).function.simpleName.toString();
    functions_trace.add(name);

    return functionToParser(thing, name);
  }
  if(thing is String) return new TokenParser(new TokenDefinition(value:thing),
                                             hasName? name : thing);
  if(thing is Parser) return thing;
  if(thing is Token) return new TokenParser(new TokenDefinition(type:thing),
                                            hasName? name : '${thing.runtimeType}');
  throw 'Unable to convert type known [${thing.runtimeType}] to Parser';
}

var functions_trace = [];
Parser functionToParser(Function fn, name){
  if(_inCall.contains('$name')){
    var thing = cache['$name'];
    return new Lazy(thing, name);
  }
  else _inCall.add('$name');
  return cache.putIfAbsent('$name', () => toParser(fn(), name));
}
