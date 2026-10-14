import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = false;

  late final FileLoader _fileLoader = FileLoader.fromAsset(
    "assets/login-bear-animation.riv",
    riveFactory: Factory.rive,
  );

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Obtener el tamaño de la pantalla del dispositivo
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveWidgetBuilder(
                  fileLoader: _fileLoader,
                  builder: (context, state) => switch (state) {
                    RiveLoaded() => RiveWidget(controller: state.controller),
                    RiveFailed() => const Center(
                        child: Text("No se pudo cargar la animación"),
                      ),
                    RiveLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
