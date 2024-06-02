import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:movie_app/components/model_video.dart';
import 'package:movie_app/pages/page_detail.dart';
import 'package:movie_app/video_player/video_player.dart';

class PageHomeMovie extends StatefulWidget {
  const PageHomeMovie({super.key});

  @override
  State<PageHomeMovie> createState() => _PageHomeMovieState();
}

class _PageHomeMovieState extends State<PageHomeMovie> {
  int index = 0;

  // ĐĂNG NHẬP
  bool _isLoggedIn = false; // BIẾN KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP
  User? _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DANH SÁCH VIDEO YÊU THÍCH
  final List<MovieSnapshot> _favoriteMovies = [];

  // TEXTFIELD ĐĂNG NHẬP / ĐĂNG KÝ
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false; // BIẾN ẨN / HIỆN MẬT KHẨU

  // BIẾN KIỂM TRA NGƯỜI DÙNG MUỐN ĐĂNG NHẬP HAY ĐĂNG KÝ
  bool _isSignUp = false;

  // TÌM KIẾM
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Phương thức trả về các sự kiện khi trạng thái xác thực của người dùng thay đổi
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        setState(() {
          _isLoggedIn = false;
          _favoriteMovies.clear();
        });
      } else {
        setState(() {
          _isLoggedIn = true;
          _user = user; // Lưu thông tin người dùng vào biến _user
          _loadListFavorite();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadListFavorite() async {
    // Nếu _user = null thì thoát khỏi phương thức
    if (_user == null) return;

    final favMoviesSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid) // Truy cập vào doc có ID bằng với uid (user id) của người dùng hiện tại
        .collection('favoriteMovies')
        .get();

    setState(() {
      _favoriteMovies.clear();
      // Duyệt qua tất cả các documents trong kết quả truy vấn.
      for (var doc in favMoviesSnapshot.docs) {
        _favoriteMovies.add(MovieSnapshot.fromDocument(doc));
      }
    });
  }

  Future<void> _addToListFavorite(MovieSnapshot movie) async {
    if (_user == null) return;

    // Truy cập bộ sưu tập favoriteMovies của người dùng hiện tại trong Firestore.
    final favCollection = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('favoriteMovies');

    if (_favoriteMovies.any((m) => m.movie.id == movie.movie.id)) {
      await favCollection.doc(movie.movie.id).delete();
      setState(() {
        _favoriteMovies.removeWhere((m) => m.movie.id == movie.movie.id);
      });
      showMySnackBar(context, "Đã xóa khỏi danh sách yêu thích", 1);
    } else {
      // Thêm doc của bộ phim vào Firestore
      await favCollection.doc(movie.movie.id).set(movie.toJson());
      setState(() {
        _favoriteMovies.add(movie);
      });
      showMySnackBar(context, "Đã thêm vào danh sách yêu thích", 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "LARVA TUBA",
          style: TextStyle(
              color: Colors.black87,
              fontSize: 25,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB74D),
      ),

      backgroundColor: const Color(0xFFFFF3E0),

      body: _buildBody(context, index),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFFE0B2),
        currentIndex: index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 40),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, size: 40),
            label: "Video yêu thích",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded, size: 40),
            label: "Tài khoản",
          ),
        ],
        selectedItemColor: Colors.amber[800],
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
      ),
    );
  }

  _buildBody(BuildContext context, int index) {
    switch (index) {
      case 0:
        return _buildHome(context);
      case 1:
        return _buildFav(context);
      case 2:
        return _buildAcc(context);
    }
  }

  Widget _buildHome(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm kiếm video... ",
            filled: true,
            fillColor: const Color(0xFFFFF3E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: const Color(0xFFFFB74D),
      ),

      backgroundColor: const Color(0xFFFFF3E0),

      body: StreamBuilder<List<MovieSnapshot>>(
        stream: MovieSnapshot.getALL(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var list = snapshot.data!;

          // Lọc danh sách phim dựa trên _searchQuery
          var filteredList = list.where((movie) {
            return movie.movie.ten.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 15),
            child: ListView.separated(
              itemBuilder: (context, index) {
                var msn = filteredList[index];
                bool isFavorite = _favoriteMovies.any((movie) => movie.movie.id == msn.movie.id);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Slidable(
                      endActionPane: ActionPane(
                        extentRatio: 0.27,
                        motion: const BehindMotion(),
                        children: [
                          SlidableAction(
                            flex: 2,
                            onPressed: (context) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PageDetail(movieSnapshot: msn),
                                ),
                              );
                            },
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            icon: Icons.info_outline,
                            label: "Chi tiết",
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MyVideoPlayer(movieSnapshot: msn),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5, left: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              msn.movie.anh!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 40,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        if (_isLoggedIn) {
                          _addToListFavorite(msn);
                        } else {
                          showMySnackBar(context, "Vui lòng đăng nhập", 1);
                        }
                      },
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) => const Divider(thickness: 0),
              itemCount: filteredList.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFav(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm kiếm video yêu thích... ",
            filled: true,
            fillColor: const Color(0xFFFFF3E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: const Color(0xFFFFB74D),
      ),

      body: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        body: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _favoriteMovies.isNotEmpty
              ? ListView.builder(
                  itemCount: _favoriteMovies
                      .where((movie) => movie.movie.ten.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .length,
                  itemBuilder: (context, index) {
                    var filteredList = _favoriteMovies
                        .where((movie) => movie.movie.ten.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();
                    var msn = filteredList[index];

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          msn.movie.anh!,
                        ),
                      ),
                      title: Text(
                        msn.movie.ten,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Thời lượng: ${msn.movie.thoiLuong} phút",
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black,
                          size: 35,
                        ),
                        onPressed: () {
                          _addToListFavorite(msn);
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MyVideoPlayer(movieSnapshot: msn),
                          ),
                        );
                      },
                    );
                  },
                )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/list_empty.png',
                        width: 250,
                        height: 250,
                      ),
                    ],
                  ),
                  const Text(
                      "Danh sách trống",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange
                      ),
                  )
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAcc(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        // KIỂM TRA ĐÃ ĐĂNG NHẬP HAY CHƯA
        child: _isLoggedIn
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/hello.png',
                      width: 200,
                    ),

                    Image.asset(
                      'assets/images/slogan.png',
                      width: 350,
                    ),

                    const SizedBox(height: 50),

                    Text(
                      "${_auth.currentUser?.email}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                        setState(() {
                          _isLoggedIn = false;
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      style: const ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll( Color(0xFFFFB74D)),
                          fixedSize: MaterialStatePropertyAll(Size.fromHeight(50))
                      ),
                      child: const Text(
                        "Đăng xuất",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
            )

            : Center(
                child: Padding(
                padding: const EdgeInsets.all(20),

                // KIỂM TRA ĐỂ CHUYỂN HƯỚNG TRANG ĐĂNG KÝ
                child: !_isSignUp
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/login.png',
                              width: 200,
                              height: 200,
                            ),

                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: "Mật khẩu",
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.orange,
                                  ),
                                  color: Colors.orange,
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _auth.signInWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                                } catch (e) {
                                  showMySnackBar(context, "Email hoặc mật khẩu không chính xác!", 1);
                                }
                              },
                              style: const ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll( Color(0xFFFFB74D)),
                                  fixedSize: MaterialStatePropertyAll(Size.fromHeight(50))
                              ),
                              child: const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Bạn chưa có tài khoản?",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),

                                const SizedBox(width: 20,),

                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSignUp = true; // Chuyển sang trang đăng ký mới
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                    elevation: MaterialStateProperty.all(0),
                                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  ),
                                  child: const Text(
                                    "Đăng ký",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )

                              ],
                            )
                          ],
                        ),
                      )

                    : SingleChildScrollView(
                        child: Column( // Nếu là trang đăng ký mới
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/login.png',
                              width: 200,
                              height: 200,
                            ),

                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: "Mật khẩu",
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.orange,
                                  ),
                                  color: Colors.orange,
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: "Nhập lại mật khẩu",
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.orange,
                                  ),
                                  color: Colors.orange,
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (_passwordController.text != _confirmPasswordController.text) {
                                    showMySnackBar(context, "Mật khẩu không khớp", 1);
                                    return;
                                  }
                                  await _auth.createUserWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                                  showMySnackBar(context, "Đăng ký thành công", 1);
                                } catch (e) {
                                  showMySnackBar(context, "Email hoặc mật khẩu không hợp lệ", 1);
                                }
                              },
                              style: const ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll( Color(0xFFFFB74D)),
                                  fixedSize: MaterialStatePropertyAll(Size.fromHeight(50))
                              ),
                              child: const Text(
                                "Đăng ký",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Bạn đã có tài khoản?",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),

                                const SizedBox(width: 20,),

                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSignUp = false; // Chuyển trở lại trang đăng nhập
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                    elevation: MaterialStateProperty.all(0),
                                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  ),
                                  child: const Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )

                              ],
                            )
                          ],
                        ),
                      ),
                ),
            ),
      ),
    );
  }
}

void showMySnackBar(BuildContext context, String message, int second) {
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
    ),
  );
}