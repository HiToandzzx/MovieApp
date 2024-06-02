import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movie_app/components/model_video.dart';
import 'package:movie_app/video_player/video_player.dart';

class PageDetail extends StatefulWidget {
  MovieSnapshot movieSnapshot;

  PageDetail({required this.movieSnapshot, super.key});

  @override
  State<PageDetail> createState() => _PageDetailState();
}

class _PageDetailState extends State<PageDetail> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movieSnapshot.movie.ten,
          style: const TextStyle(
              color: Colors.black87,
              fontSize: 30,
              fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.orangeAccent[200],
      ),

      backgroundColor: const Color(0xFFFFF3E0),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                    widget.movieSnapshot.movie.anhMoTa!,
                )
            ),

            const SizedBox(height: 30,),

            Text(
              widget.movieSnapshot.movie.moTa!,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 23,
              ),
            ),

            const SizedBox(height: 30,),

            Row(
              children: [
                Text(
                  "Thời lượng: ${double.tryParse(widget.movieSnapshot.movie.thoiLuong!) ?? 0.0} phút",
                  style: const TextStyle(
                    fontSize: 23,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30,),

            Row(
              children: [
                const Text(
                    "Đánh giá: ",
                  style: TextStyle(
                    fontSize: 25
                  ),
                ),

                RatingBar.builder(
                  initialRating: double.tryParse(widget.movieSnapshot.movie.rating!) ?? 0.0,
                  itemCount: 5,
                  allowHalfRating: true,
                  tapOnlyMode: true,
                  itemBuilder: (context, index) => Icon(
                      Icons.star,
                    color: Colors.yellow[900],
                  ),
                  onRatingUpdate: (value) => print(value),
                ),
              ],
            ),

            const SizedBox(height: 30,),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/red.png',
                  width: 90,
                  height: 90,
                ),

                const SizedBox(width: 9,),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MyVideoPlayer(movieSnapshot: widget.movieSnapshot,),
                        )
                    );
                  },

                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll( Color(0xFFFFB74D)),
                      fixedSize: MaterialStatePropertyAll(Size.fromHeight(50))
                  ),

                  child: const Text(
                    "Xem phim",
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.black87,
                    ),
                  ),
                ),

                Image.asset(
                  'assets/images/yellow.png',
                  width: 120,
                  height: 120,
                ),
              ],
            )

          ],
        ),
      ),

    );
  }
}
