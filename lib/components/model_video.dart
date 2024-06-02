import 'package:cloud_firestore/cloud_firestore.dart';

// LỚP MÔ TẢ DỮ LIỆU
class Movie {
  String id, ten;
  String? thoiLuong;
  String? moTa;
  String? anh;
  String? anhMoTa;
  String? video;
  String? rating;

  Movie({
    required this.id,
    required this.ten,
    this.thoiLuong,
    this.anh,
    this.anhMoTa,
    this.moTa,
    this.video,
    this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'thoiLuong': thoiLuong,
      'anh': anh,
      'anhMoTa': anhMoTa,
      'moTa': moTa,
      'video': video,
      'rating': rating,
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      ten: json['ten'] as String,
      thoiLuong: json['thoiLuong'] as String?,
      anh: json['anh'] as String?,
      anhMoTa: json['anhMoTa'] as String?,
      moTa: json['moTa'] as String?,
      video: json['video'] as String?,
      rating: json['rating'] as String?,
    );
  }
}

// LỚP TRUY CẬP DỮ LIỆU
class MovieSnapshot {
  Movie movie;
  DocumentReference ref;

  MovieSnapshot({
    required this.movie,
    required this.ref,
  });

  factory MovieSnapshot.fromDocument(DocumentSnapshot docSnap) {
    return MovieSnapshot(
      movie: Movie.fromJson(docSnap.data() as Map<String, dynamic>),
      ref: docSnap.reference,
    );
  }

  Map<String, dynamic> toJson() {
    return movie.toJson();
  }

  static Future<DocumentReference> them(Movie movie) async {
    return FirebaseFirestore.instance.collection("Movies").add(movie.toJson());
  }

  Future<void> capNhat() async {
    ref.update(movie.toJson());
  }

  Future<void> xoa() async {
    ref.delete();
  }

  // TRUY VẤN THEO THỜI GIAN THỰC
  static Stream<List<MovieSnapshot>> getALL() {
    Stream<QuerySnapshot> sqs = FirebaseFirestore.instance.collection("Movies").snapshots();
    return sqs.map((qs) => qs.docs.map(
            (docSnap) => MovieSnapshot.fromDocument(docSnap)
    ).toList());
  }

  // TRUY VẤN DỮ LIỆU 1 LẦN
  static Future<List<MovieSnapshot>> getALL_2() async {
    QuerySnapshot qs = await FirebaseFirestore.instance.collection("Movies").get();
    return qs.docs.map(
            (docSnap) => MovieSnapshot.fromDocument(docSnap)
    ).toList();
  }
}

