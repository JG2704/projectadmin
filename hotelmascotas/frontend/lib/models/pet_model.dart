class Pet {
  int? id;
  String name, type, breed, age;
  String gender, weight, birthDate, vaccines, allergies, diet, notes;

  Pet({
    this.id, required this.name, required this.type, required this.breed, required this.age,
    this.gender = "No especificado", this.weight = "No especificado",
    this.birthDate = "No especificado", this.vaccines = "No especificado",
    this.allergies = "Ninguna", this.diet = "Normal", this.notes = "",
  });
}