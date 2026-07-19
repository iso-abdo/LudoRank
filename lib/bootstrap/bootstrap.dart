import 'package:flutter/material.dart';

import 'package:ludo_rank/app/app.dart';

import 'initialize.dart';



Future<void> bootstrap() async {


  await initialize();


  runApp(
    const LudoRankApp(),
  );


}