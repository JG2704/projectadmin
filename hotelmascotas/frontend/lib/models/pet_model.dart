class Pet {
  int? id;

  String name;
  String age;

  String? size;
  String? vaccines;
  String? condition;
  String? contract;
  String? specialCare;

  int? genderInt; // 0 = macho, 1 = hembra

  Pet({
    this.id,
    required this.name,
    required this.age,
    this.size,
    this.vaccines = "No especificado",
    this.condition = "Desconocida",
    this.contract = "No definido",
    this.specialCare = "Ninguno",
    this.genderInt,
  });

  String get genderLabel {
    if (genderInt == 0) return "Macho";
    if (genderInt == 1) return "Hembra";
    return "No especificado";
  }
}