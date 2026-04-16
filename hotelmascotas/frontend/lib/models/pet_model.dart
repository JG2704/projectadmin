import 'package:flutter/material.dart';

class Pet {
  int? id;

  String name;
  String age;

  // Campos usados por las pantallas de mascotas
  String type;
  String breed;
  String gender;
  String weight;
  String birthDate;
  String conditions;
  String diet;
  String notes;

  // Campos usados por formularios / edición
  String? size;
  String vaccines;
  String? condition;
  String? contract;
  String? specialCare;

  int? genderInt; // 0 = macho, 1 = hembra

  Pet({
    this.id,
    required this.name,
    required this.age,
    this.type = "Desconocido",
    this.breed = "Desconocida",
    this.gender = "No especificado",
    this.weight = "No especificado",
    this.birthDate = "No especificado",
    this.conditions = "Ninguna",
    this.diet = "Normal",
    this.notes = "",
    this.size,
    this.vaccines = "No especificado",
    this.condition = "Desconocida",
    this.contract = "No definido",
    this.specialCare = "Ninguno",
    this.genderInt,
  });

  factory Pet.fromBackend(Map<String, dynamic> item) {

    debugPrint("Especie y raza recibidos del backend con tipo de datos: ${item['especie'].runtimeType} / ${item['raza'].runtimeType}");

    return Pet(
      id: item['id'] as int?,
      name: item['nombre']?.toString() ?? "Sin nombre",
      age: (item['edad'] ?? 0).toString(),
      type: item['especie']?.toString() ?? "Desconocido",
      breed: item['raza']?.toString() ?? "Desconocida",
      gender: item['sexo']?.toString() ?? "No especificado",
      weight: item['peso']?.toString() ?? "No especificado",
      birthDate: item['fecha_nacimiento']?.toString() ?? "No especificado",
      conditions: item['conditions']?.toString() ?? "Ninguna",
      diet: item['dieta']?.toString() ?? "Normal",
      notes: item['notas']?.toString() ?? "",
      size: item['altura']?.toString() ??
          item['tamaño']?.toString() ??
          item['tamano']?.toString(),
      vaccines: item['vacunacion']?.toString() ??
          item['vacunas']?.toString() ??
          "No especificado",
      condition: item['condicion']?.toString() ?? "Desconocida",
      contract: item['contrato']?.toString() ?? "No definido",
      specialCare:
          item['cuidados_especiales']?.toString() ?? "Ninguno",
);
  }

  String get genderLabel {
    if (gender.isNotEmpty) return gender;
    if (genderInt == 0) return "Macho";
    if (genderInt == 1) return "Hembra";
    return "No especificado";
  }

  String get displayWeight {
    if (weight.isNotEmpty && weight != "No especificado") {
      return weight;
    }
    if (size != null && size!.isNotEmpty) {
      return size!;
    }
    return "No especificado";
  }


}