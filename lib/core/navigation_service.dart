import 'package:flutter/material.dart';

/// Clave global del Navigator de la app. Necesaria para abrir dialogos desde
/// widgets montados en `MaterialApp.builder`: ese builder inserta su arbol
/// POR ENCIMA del Navigator, asi que su `BuildContext` no tiene un Navigator
/// ancestro y `showDialog` fallaria. Con esta clave se obtiene un contexto
/// que si esta dentro del Navigator.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
