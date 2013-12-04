part of parser;

List<inspect> GLOBAL_INSPECTION = <inspect>[];

typedef void inspect(Inspector inspector);

class Inspector {
  inspect(){
    for(final inspect in GLOBAL_INSPECTION)
      inspect(this);
  }
}
