import 'package:flutter/material.dart';
import 'package:caixafacil_app/view/listar_agencias.dart';

void main(){
  runApp(const CaixaFacilApp());
}

class CaixaFacilApp extends StatelessWidget {
  const CaixaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListarAgencias(),
    );
  }
}