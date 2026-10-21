import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer

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
  
  //2.2 Crear los listeners (Oyentes/Chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if(_emailFocusNode.hasFocus){
        //Verificar que no sea nulo
        if(_isHandsUp != null){
          //Ojos sin cerrar en email
          _isHandsUp?.change(false);
          _numLook?.value = 50; //Mirada neutral
        }
      }
    );

    _passwordFocusNode.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });



  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: ['Login Machine'],
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
		  //2.3 Asignar foco al compo de texto
		  focusNode: _emailFocusNode, 
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //_isHandsUp!.change(false);
                    }
                    if (_isChecking != null) return; 
                      _isChecking!.change(true);
                      //3.4 Implementar numLook
                      //Ajustes del 0 al 100
                      //80 es medida de calibración. Clamp es el rango(Abrazadera)
                      final look = (value.length / 80.0 *100).clamp(loweLimit, upperLimit);
                      _numLook?.value = look;

                      //3.5 Debounce: Si vuelve a teclear, reinicia el contador
                      _typingDebounce?.cancel(); // Cancelamos cualquier timer existente
                      //Crear nuevo timer
                      _typingDebounce = Timer(const Duration(3),(){
                      if (!mounted) return;
                      _isChecking?.change(false);
                      });

                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "email@ejemplo.com",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
		  //2.3 Asignar foco al compo de texto
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
      ),
    );
  }
  @override
  void dispose() {
    //2.4 Liberar recursos de los focusNode
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    //3.5 Liberar Timer
    _typingDebounce?.cancel();
    super.dispose();
}   
