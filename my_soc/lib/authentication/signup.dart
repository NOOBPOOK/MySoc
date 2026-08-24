import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:page_transition/page_transition.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  static Future<void>? _googleSignInInitialization;

  bool isSecured = true;
  bool userAgreement = false;

  final TextEditingController username = TextEditingController();
  final TextEditingController passwd = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  @override
  // Backend: Disposes form controllers when the page is removed.
  void dispose() {
    username.dispose();
    passwd.dispose();
    super.dispose();
  }

  // Backend: Creates a Firebase account with email and password, then routes to email verification.
  Future<void> createUserAccount() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: username.text.trim(),
        password: passwd.text.trim(),
      );

      print("Created user account");
      await Future.delayed(const Duration(seconds: 2));

      await context.pushNamedTransition(
        routeName: '/emailverify',
        type: PageTransitionType.fade,
        duration: Duration(milliseconds: 200),
      );
    } on FirebaseAuthException catch (e) {
      print(e.toString());
    }
  }

  // Backend: Initializes the Google Sign-In client once for this page.
  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??=
        GoogleSignIn.instance.initialize();
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
        await _ensureGoogleSignInInitialized();

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          _showErrorSnackBar(
              'Google Sign-In is not supported on this platform.');
          return;
        }

        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        if (idToken == null) {
          _showErrorSnackBar('Google Sign-In did not return an ID token.');
          return;
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) {
        return;
      }

      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/userdash',
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

  // Backend: Validates the signup form and starts account creation when allowed.
  void _handleCreateAccount() {
    if (_formkey.currentState!.validate()) {
      if (!userAgreement) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to our terms'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        createUserAccount();
      }
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

  // UI: Signup form header.
  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create Account",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: "Readex Pro",
            color: Color(0xFF222A54),
          ),
        ),
        Text(
          "Your journey starts here sign up now!",
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

  // UI: Shared input decoration for signup text fields.
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

  // UI: Terms and conditions agreement row.
  Widget _buildAgreementRow() {
    return Row(
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Transform.scale(
            scale: 0.7,
            child: Checkbox(
              activeColor: Color(0xFFACACAC),
              value: userAgreement,
              onChanged: (bool? value) {
                setState(() {
                  userAgreement = value!;
                });
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            "I agree to terms and condition of user",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: Color(0xFF3F72AF),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Create account button.
  Widget _buildCreateAccountButton() {
    return ElevatedButton(
      onPressed: _handleCreateAccount,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(280, 40),
        backgroundColor: Color(0xFF222A54),
      ),
      child: Text(
        "Create my Account",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  // UI: Google signup button.
  Widget _buildGoogleSignupButton() {
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
        "Continue with Google",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  // UI: Divider text between signup methods.
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

  // UI: Login navigation link.
  Widget _buildLoginLink() {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          text: "Already have an account? ",
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
                  Navigator.pop(context);
                },
              text: "Login",
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

  // UI: Grouped action section for agreement, buttons, and login link.
  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAgreementRow(),
            SizedBox(height: 10),
            _buildCreateAccountButton(),
            SizedBox(height: 5),
            _buildDividerText(),
            SizedBox(height: 5),
            _buildGoogleSignupButton(),
            SizedBox(height: 10),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  // UI: Main signup form card.
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
                SizedBox(height: 20),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  // UI: Root signup page layout.
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
