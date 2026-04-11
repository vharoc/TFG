import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {

  final String id;
  final String nombre;
  final String email;
  
  Usuario({
    required this.id,
    required this.nombre,
    required this.email
  });

  factory Usuario.fromMap(Map<String, dynamic> map, String id){
    return Usuario(
      id: id,
      nombre: map['nombre'] ?? '', 
      email: map['email'] ?? '',
    );
  }

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    return Usuario.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap(){
    return{
      'nombre': nombre,
      'email': email,
    };
  }

  Usuario copyWith({
    String? nombre,
    String? email,
  }) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
    );
  }


}