import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseServices {

  Future<UserCredential?> loginUsingGoogle() async {

    try{
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if(googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }catch(e){
      return null;
    }
  }
  Future<void> signUp(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("User registered: ${userCredential.user!.email}");
  } catch (e) {
    print("Error: $e");
  }
}
Future<UserCredential> signIn(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("User logged in: ${userCredential.user!.email}");
    return userCredential;
  } catch (e) {
    print("Error: $e");
    throw e; // Re-throw the error so it can be caught by the UI
  }
}
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
  print("User signed out");
}
  
}