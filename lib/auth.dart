// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:bate_ponto/shared/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = "";
  var _enteredPassword = "";
  File? _selectedImage;
  bool _isAuthenticating = false;
  var _enteredUsername = "";

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || (!_isLogin && _selectedImage == null)) {
      return;
    }

    _formKey.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        // final userCredentials =
        await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        // print(userCredentials);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredentials.user?.uid}.jpg");

        await storageRef.putFile(_selectedImage!);

        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredentials.user?.uid)
            .set({
          "username": _enteredUsername,
          "email": _enteredEmail,
          "image_url": imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      FirebaseAuth.instance.signOut();
      if (error.code == 'email-already-in-use') {
        // ...
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? "Authentication failed")),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on FirebaseException catch (error) {
      FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? "Authentication failed")),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _newSubmit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || (!_isLogin && _selectedImage == null)) {
      return;
    }

    _formKey.currentState!.save();

    var actionCodeSettings = ActionCodeSettings(
      url: 'https://www.example.com/finishSignUp?cartId=1234',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.ios',
      androidPackageName: 'com.example.bate_ponto',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    FirebaseAuth.instance
        .sendSignInLinkToEmail(
          email: _enteredEmail,
          actionCodeSettings: actionCodeSettings,
        )
        .catchError(
            (onError) => print('Error sending email verification $onError'))
        .then((value) => print('Successfully sent email verification'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container(
              //   margin: const EdgeInsets.only(
              //     top: 30,
              //     bottom: 20,
              //     left: 20,
              //     right: 20,
              //   ),
              //   width: 200,
              //   child: Image.asset("assets/images/chat.png"),
              // ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains("@")) {
                                return "Please enter a valid email address.";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredEmail = newValue ?? "";
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Username",
                              ),
                              enableSuggestions: true,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length < 4) {
                                  return "Please enter a least 4 characters";
                                }
                                return null;
                              },
                              onSaved: (value) => _enteredUsername = value!,
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return "Password mus be at least 6 characters long.";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _enteredPassword = newValue ?? "";
                            },
                            onFieldSubmitted: (value) => _submit(),
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? "Login" : "Signup"),
                            ),
                          const SizedBox(height: 5),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? "Create an account"
                                  : "I already have an account"),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
