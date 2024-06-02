import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:movie_app/pages/page_connect_fb.dart';

void main() async {
  // Đảm bảo rằng các widget trong ứng dụng Flutter được khởi tạo và sẵn sàng sử dụng
  WidgetsFlutterBinding.ensureInitialized();

  //Đảm bảo Firebase đã được khởi tạo trước khi ứng dụng tiếp tục
  await Firebase.initializeApp();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MovieApp(),
    );
  }
}
