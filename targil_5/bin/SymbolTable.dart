class SymbolEntry {
  //variable name
  final String name;
  //var type
  final String type;
  //var kind (field/static/arg...)
  final String segment;
  //var offset in its scope
  final int offset;

  SymbolEntry(this.name, this.type, this.segment, this.offset);
}

class SymbolTable {
  final List<SymbolEntry> table = [];

  exist(name) {
    return table.any((entry) => entry.name == name);
  }

  SymbolEntry findByName(name) {
    return table.firstWhere((entry) => entry.name == name);
  }

  //adds a entry to the symbol table 
  add(name, type, segment) {
    //if that kind of segment has entries so put the new one below
    int offset = table.any((entry) => entry.segment == segment)
        ? table.lastWhere((entry) => entry.segment == segment).offset + 1
        : 0;
    table.add(SymbolEntry(name, type, segment, offset));
  }

  clear() {
    table.clear();
  }
  //returns the amount of segments
  segmentLength(segment) {
    return table.any((entry) => entry.segment == segment)
        ? table.lastWhere((entry) => entry.segment == segment).offset + 1
        : 0;
  }
}