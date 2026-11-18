import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;

  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  //2.1 Crear variables para focusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //4.1 Crear controllers para manipular el texto
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostrarlo en la UI
  String? emailError;
  String? passError;

  //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;

  //4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 símbolo
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    //4.5 De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    //4.6 Evaluar los errores
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    //4.7 Avisar que hubo cambios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus(); //Quita el foco
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 Si algún campo tiene formato inválido, activar fallo y detener aquí
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    //5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      //5.5 Autenticar usuario en Firebase (esperamos un par de segundos para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      //5.6 Apagar loading, disparar éxito del osito y esperar a que termine su animación
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar a la pantalla de productos de Spring Boot
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } catch (e) {
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      setState(() {
        _isLoading = false;
        passError = "Credenciales incorrectas en Firebase";
      });
      _trigFail?.fire();
    }
  }

  //2.2 Crear los listeners (Oyentes/Chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        //Verificar que no sea nulo
        if (_isHandsUp != null) {
          //Ojos sin cerrar en email
          _isHandsUp?.change(false);
          _numLook?.value = 50.0; //Mirada neutral
        }
      }
    });

    _passwordFocusNode.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      if (_controller == null) return;
                      artboard.addController(_controller!);
                      _isChecking = _controller?.findSMI('isChecking');
                      _isHandsUp = _controller?.findSMI('isHandsUp');
                      _trigSuccess = _controller?.findSMI('trigSuccess');
                      _trigFail = _controller?.findSMI('trigFail');
                      _numLook = _controller?.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  //4.10 Asignar controller al TextField
                  controller: _emailCtrl,
                  //2.3 Asignar foco al campo de texto
                  focusNode: _emailFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //_isHandsUp!.change(false);
                    }
                    if (_isChecking == null) return;
                    _isChecking!.change(true);
                    //3.4 Implementar numLook
                    //Ajustes del 0 al 100
                    //80 es medida de calibración. Clamp es el rango(Abrazadera)
                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
                    _numLook?.value = look;

                    //3.5 Debounce: Si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel(); // Cancelamos cualquier timer existente
                    //Crear nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: "email@ejemplo.com",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  //4.10 Asignar controller al TextField
                  controller: _passCtrl,
                  //2.3 Asignar foco al campo de texto
                  focusNode: _passwordFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //_isHandsUp!.change(true);
                    }
                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    errorText: passError,
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
                const SizedBox(height: 10),
                //4.12 Texto "Forgot your password?"
                SizedBox(
                  width: size.width,
                  child: const Text(
                    "Forgot your password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                //4.13 Botón de login
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  //5.9 Mostrar CircularProgressIndicator si está cargando, o el texto Login
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                //4.14 ¿No tienes cuenta?
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //4.11 Liberar recursos de los controllers
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar recursos de los focusNode
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    //3.5 Liberar Timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}
