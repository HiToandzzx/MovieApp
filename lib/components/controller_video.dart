import 'package:get/get.dart';
import 'package:movie_app/components/model_video.dart';

class SimpleController extends GetxController{
  List<Movie> _listMovie = [];

  List<Movie> get listMovie => _listMovie;


  static SimpleController get() => Get.find<SimpleController>();

  @override
  void onReady() {
    super.onReady();
    docDL();
  }

  Future<void> docDL() async{
    var list = await MovieSnapshot.getALL_2();

    _listMovie = list.map((movieSnap) => movieSnap.movie).toList();
    update(["listMovies"]);
  }
}

class MovieBinding extends Bindings{
  @override
  void dependencies() {
    Get.put(SimpleController());
  }
}


