import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movie_app/components/controller_video.dart';
import 'package:movie_app/pages/page_home_movie_app.dart';
import 'package:movie_app/widget_connect_fb.dart';

class MovieApp extends StatefulWidget {
  const MovieApp({super.key});

  @override
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  @override
  Widget build(BuildContext context) {
    return MyFirebaseConnect(
        errorMessage: "Error",
        connectingMessage: "Connecting...",
        builder: (context) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialBinding: MovieBinding(),
          home: const PageHomeMovie(),
        ),
    );
  }
}



