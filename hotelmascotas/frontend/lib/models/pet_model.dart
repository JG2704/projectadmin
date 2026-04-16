class Pet {
  int? id;

  String name;
  String age;

  String type;
  String breed;
  String gender;
  String weight;
  String birthDate;
  String allergies;
  String diet;
  String notes;

  String size;
  String vaccines;
  String condition;
  String contract;
  String specialCare;

  int? genderInt;

  Pet({
    this.id,
    required this.name,
    required this.age,
    this.type = "Desconocido",
    this.breed = "Desconocida",
    this.gender = "No especificado",
    this.weight = "No especificado",
    this.birthDate = "No especificado",
    this.allergies = "Ninguna",
    this.diet = "Normal",
    this.notes = "",
    this.size = "",
    this.vaccines = "No especificado",
    this.condition = "Desconocida",
    this.contract = "No definido",
    this.specialCare = "Ninguno",
    this.genderInt,
  });

  factory Pet.fromBackend(Map<String, dynamic> item) {
    final rawSexo = item['sexo'];

    int? sexoInt;
    if (rawSexo is int) {
      sexoInt = rawSexo;
    } else if (rawSexo != null) {
      sexoInt = int.tryParse(rawSexo.toString());
    }

    String genderText;
    if (rawSexo is String && rawSexo.trim().isNotEmpty) {
      genderText = rawSexo;
    } else if (sexoInt == 0) {
      genderText = "Macho";
    } else if (sexoInt == 1) {
      genderText = "Hembra";
    } else {
      genderText = "No especificado";
    }

    return Pet(
      id: item['id'],
      name: item['nombre']?.toString() ?? 'Sin nombre',
      age: (item['edad'] ?? 0).toString(),
      type: item['especie']?.toString() ?? 'Desconocido',
      breed: item['raza']?.toString() ?? 'Desconocida',
      gender: genderText,
      weight: item['peso']?.toString() ??
          item['tamaño']?.toString() ??
          'No especificado',
      birthDate: item['fecha_nacimiento']?.toString() ?? 'No especificado',
      allergies: item['alergias']?.toString() ?? 'Ninguna',
      diet: item['dieta']?.toString() ?? 'Normal',
      notes: item['notas']?.toString() ?? '',
      size: item['tamaño']?.toString() ?? '',
      vaccines: item['vacunacion']?.toString() ??
          item['vacunas']?.toString() ??
          'No especificado',
      condition: item['condicion']?.toString() ?? 'Desconocida',
      contract: item['contrato']?.toString() ?? 'No definido',
      specialCare: item['cuidados_especiales']?.toString() ?? 'Ninguno',
      genderInt: sexoInt,
    );
  }

  String get genderLabel {
    if (gender.isNotEmpty) return gender;
    if (genderInt == 0) return "Macho";
    if (genderInt == 1) return "Hembra";
    return "No especificado";
  }
}