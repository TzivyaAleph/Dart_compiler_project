class Person {
  late String name;
  late int age;
}

void main() {
  var person = Person();
  person.name = 'John';
  person.age = 30;
  
  print(person.toString());
}