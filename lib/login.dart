import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_home_page.dart'; // Ensure this file exists and is properly set up

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AnimationController? _animationController;
  Animation<double>? _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: Colors.deepOrange[800], // Brick color tone for AppBar
      ),
      body: FadeTransition(
        opacity: _opacityAnimation!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.deepOrange[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange[700]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.deepOrange[900]!, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: Colors.deepOrange[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange[700]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.deepOrange[900]!, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 10,
                  shadowColor: Colors.deepOrange[900],
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 36),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed))
                        return Colors.deepOrange[900]!;
                      return Colors.deepOrange[800]!;
                    },
                  ),
                ),
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final User? user = credential.user;
      if (user != null) {
        String userId = '';
        if (user.email == 'mxtruongqb656@gmail.com') {
          await user.updateDisplayName('truong');
        } else if (user.email == 'taiphanvan2403@gmail.com') {
          await user.updateDisplayName('tai');
        }
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MyHomePage(cameras: widget.cameras),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to sign in with Email & Password"),
          backgroundColor: Colors.deepOrange[800],
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController?.dispose();
    super.dispose();
  }
}
