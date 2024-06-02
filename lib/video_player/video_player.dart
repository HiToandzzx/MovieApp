import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:movie_app/components/model_video.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';


class MyVideoPlayer extends StatefulWidget {
  final MovieSnapshot movieSnapshot;

  const MyVideoPlayer({required this.movieSnapshot, Key? key}) : super(key: key);

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late FlickManager flickManager;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = [];

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse(widget.movieSnapshot.movie.video!),
      ),
    );
  }

  @override
  void dispose() {
    flickManager.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movieSnapshot.movie.ten!,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orangeAccent[200],
      ),

      backgroundColor: const Color(0xFF212121),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // TỈ SỐ CR VÀ CC (CR CỦA WIDGET GẤP 1.6 LẦN CC)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: FlickVideoPlayer(
                flickManager: flickManager,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                widget.movieSnapshot.movie.moTa!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    "LARVA TUBA",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Icon(
                    Icons.check_circle,
                    color: Colors.lightBlueAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              // TRUY CẬP VÀO COLLECTION comments
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  // LỌC CÁC DOCUMENT TRONG COLLECTION CÓ FIELD ID = VỚI ID CỦA VIDEO
                  .where('movie_id', isEqualTo: widget.movieSnapshot.movie.id)
                  .snapshots(),

              builder: (context, snapshot) {
                // KIỂM TRA TRẠNG THÁI KẾT NỐI

                // TRẠNG THÁI ĐỢI DỮ LIỆU
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // KIỂM TRA LỖI
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                        'Lỗi',
                        style: TextStyle(
                            color: Colors.red
                        ),
                      )
                  );
                }

                // KIỂM TRA DỮ LIỆU (NẾU KHÔNG CÓ DATA HOẶC DANH SÁCH DỮ LIỆU TRỐNG)
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 70),
                        child: Text(
                          'Video chưa có bình luận nào',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20
                          ),
                        ),
                      )
                  );
                }

                // XÓA DANH SÁCH CŨ ĐỂ KHÔNG BỊ TRÙNG
                _comments.clear();

                // DUYỆT QUA TẤT CẢ CÁC DOC
                for (var doc in snapshot.data!.docs) {
                  // THÊM COMMENT VÀO DANH SÁCH _comments
                  _comments.add(doc['comment']);
                }

                return ListView.builder(
                  // ĐẢM BẢO DANH SÁCH KHÔNG CHIẾM TOÀN BỘ KHÔNG GIAN
                  shrinkWrap: true,
                  // VÔ HIỆU HÓA THANH CUỘN CHO DANH SÁCH
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    // LẤY DỮ LIỆU THỜI GIAN TỪ SNAPSHOT
                    var timestamp = snapshot.data!.docs[index]['timestamp'];

                    var formattedTimestamp = _formatTimestamp(timestamp);

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _comments[index],
                            style: const TextStyle(
                                color: Colors.white,
                              fontSize: 20
                            ),
                          ),

                          Text(
                            formattedTimestamp,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  // KIỂU DỮ LIỆU TIMESTAMP TRONG FIREBASE
  String _formatTimestamp(Timestamp timestamp) {
    // CHUYỂN THÀNH DATETIME
    var date = timestamp.toDate();
    var formatter = DateFormat('HH:mm dd/MM/yyyy');
    // ĐỊNH DẠNG THÀNH CHUỖI
    return formatter.format(date);
  }

  void _addComment() {
    String comment = _commentController.text;

    // KIỂM TRA NẾU CÓ NỘI DUNG TRONG TEXTFIELD
    if (comment.isNotEmpty) {
      // THÊM BÌNH LUẬN MỚI VÀO COLELCTION comments
      FirebaseFirestore.instance.collection('comments')
          .add({
            'movie_id': widget.movieSnapshot.movie.id,
            'comment': comment,
            'timestamp': Timestamp.now(),
          })

      // TRƯỜNG HỢP THÊM THÀNH CÔNG
          .then((value) {
            _commentController.clear();
            showMySnackBar(context, "Bình luận thành công", 1);
          })

      // TRƯỜNG HỢP KHÔGN THÀNH CÔNG
          .catchError((error) {
            showMySnackBar(context, "Lỗi", 1);
          });
    }

    // TEXTFIELD RỖNG
    else {
      showMySnackBar(context, "Hãy nhập bình luận", 1);
    }
  }
}

showMySnackBar(BuildContext context, String message, int second){
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFFB74D),
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        duration: Duration(seconds: second),
      )
  );
}
