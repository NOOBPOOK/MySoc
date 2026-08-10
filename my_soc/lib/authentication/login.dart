import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_soc/authentication/forgotPassord.dart';
import 'package:my_soc/authentication/signup.dart';
import 'package:my_soc/watchman/watch_login.dart';
import 'package:my_soc/routes.dart';
import 'package:page_transition/page_transition.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static Future<void>? _googleSignInInitialization;

  bool isSecured = true;

  final TextEditingController username = TextEditingController();
  final TextEditingController passwd = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacementNamed(context, MySocRoutes.userDashboard);
      }
    });
  }

  @override
  // Backend: Disposes form controllers when the page is removed.
  void dispose() {
    username.dispose();
    passwd.dispose();
    super.dispose();
  }

  // Backend: Signs the user into Firebase using email and password.
  Future<void> loginUserAccount() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: username.text.trim(),
        password: passwd.text.trim(),
      );
      await Navigator.pushNamed(context, MySocRoutes.userDashboard);
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      setState(() {});
    }
  }

  // Backend: Initializes the Google Sign-In client once for this page.
  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
  }

  // Backend: Shows an error message to the user using a snackbar.
  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Backend: Authenticates the user with Google and signs them into Firebase.
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignInInitialized();

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          _showErrorSnackBar(
              'Google Sign-In is not supported on this platform.');
          return;
        }

        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        if (idToken == null) {
          _showErrorSnackBar('Google Sign-In did not return an ID token.');
          return;
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) {
        return;
      }

      await Navigator.pushNamedAndRemoveUntil(
        context,
        MySocRoutes.userDashboard,
        (route) => false,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      _showErrorSnackBar('Google Sign-In failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Google Sign-In failed.');
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: $e');
    }
  }

  // Backend: Validates the login form and starts authentication.
  void _handleLogin() {
    if (_formkey.currentState!.validate()) {
      loginUserAccount();
    }
  }

  // UI: App title section.
  Widget _buildTitleSection() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      child: Center(
        child: Text(
          "MySoc",
          style: TextStyle(
            fontFamily: "Readex Pro",
            fontWeight: FontWeight.w700,
            fontSize: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // UI: Login form header.
  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back !",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: "Readex Pro",
            color: Color(0xFF222A54),
          ),
        ),
        Text(
          "We have been waiting for your return",
          style: TextStyle(
            fontFamily: "Readex Pro",
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: Color(0xFFACACAC),
          ),
        ),
      ],
    );
  }

  // UI: Email input field.
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "E-mail",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 2),
          child: SizedBox(
            height: 60,
            child: TextFormField(
              controller: username,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your email";
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                    .hasMatch(value)) {
                  return "Enter a valid email";
                }
                return null;
              },
              decoration: _buildInputDecoration("Enter your e-mail"),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Password input field.
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            height: 60,
            child: TextFormField(
              controller: passwd,
              obscureText: isSecured,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                return null;
              },
              decoration: _buildInputDecoration(
                "Enter your password",
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      isSecured = !isSecured;
                    });
                  },
                  icon: Icon(
                    isSecured ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Shared input decoration for login text fields.
  InputDecoration _buildInputDecoration(
    String hintText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      helperText: " ",
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey,
        fontFamily: "Poppins",
        fontWeight: FontWeight.w300,
        fontSize: 15,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Color(0xFFACACAC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // UI: Forgot password helper text.
  Widget _buildForgotPasswordText() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPassword(),
              ),
            );
          },
          child: Text(
            "Forgot password?",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  // UI: Login button.
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(280, 40),
        backgroundColor: Color(0xFF222A54),
      ),
      child: Text(
        "Login In",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  // UI: Google login button.
  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      icon: Image.asset(
        'C:/GithubRepos/MySoc/my_soc/lib/images/google.png',
        height: 20,
      ),
      onPressed: signInWithGoogle,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(280, 40),
        backgroundColor: Color(0xFF222A54),
      ),
      label: Text(
        "Continue with google",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  // UI: Divider text between login methods.
  Widget _buildDividerText() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        "Or",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFFACACAC),
        ),
      ),
    );
  }

  // UI: Signup navigation link.
  Widget _buildSignupLink() {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(
            fontFamily: "Poppins",
            color: Color.fromARGB(255, 193, 193, 193),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  context.pushNamedTransition(
                    routeName: MySocRoutes.signupRoute,
                    type: PageTransitionType.rightToLeft,
                    duration: Duration(milliseconds: 300),
                  );
                },
              text: "Sign up",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI: Employee sign in navigation link.
  Widget _buildEmployeeSigninLink() {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          text: "Looking for Employee Sign In? ",
          style: TextStyle(
            fontFamily: "Poppins",
            color: Color.fromARGB(255, 193, 193, 193),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WatchmanLogin()),
                  );
                },
              text: "Click Here",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI: Grouped action section for buttons and signup link.
  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 7),
            _buildLoginButton(),
            SizedBox(height: 5),
            _buildDividerText(),
            SizedBox(height: 5),
            _buildGoogleLoginButton(),
            SizedBox(height: 10),
            _buildSignupLink(),
            SizedBox(height: 10),
            _buildEmployeeSigninLink(),
          ],
        ),
      ),
    );
  }

  // UI: Main login form card.
  Widget _buildFormCard() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormHeader(),
                SizedBox(height: 20),
                _buildEmailField(),
                SizedBox(height: 10),
                _buildPasswordField(),
                _buildForgotPasswordText(),
                SizedBox(height: 30),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  // UI: Root login page layout.
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF222A54), Color(0xFFCE798E)],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                _buildTitleSection(),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
