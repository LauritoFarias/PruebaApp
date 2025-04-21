import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PruebaApp',
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/session': (context) => SessionPage(),
      },
    );
  }
}

final List<Map<String, String>> quickUsers = [
  {'email': 'ivanlaurito@hotmail.com', 'password': 'Hotmail.98'},
  {'email': 'jorgelin.maria@hotmail.com', 'password': 'aBL1970'},
  {'email': 'lucas_castelli@hotmail.com', 'password': 'Castelli.Lucas.66'},
];

enum MessageType {success, warning, failure}

void mostrarMensaje(BuildContext context, String mensaje, MessageType type) {
  Color backgroundColor;
  IconData icon;

  switch (type) {
    case MessageType.success:
      backgroundColor = Colors.green[800]!;
      icon = Icons.check_circle;
      break;
    case MessageType.failure:
      backgroundColor = Colors.yellow[800]!;
      icon = Icons.error;
      break;
    case MessageType.warning:
      backgroundColor = Colors.red[800]!;
      icon = Icons.warning;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: Duration(seconds: 3),
    ),
  );
}

// --------------------- LOGIN PAGE ---------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _mostrarPassword = false;

  Future<void> iniciarSesion() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushNamed(context, '/session');
      Session.activeUser = emailController.text.trim();
      Session.startCountdown();
      mostrarMensaje(context, '¡Inicio de sesión exitoso!', MessageType.success);
    } on FirebaseAuthException catch (e) {
      mostrarMensaje(context, e.message ?? 'Error al iniciar sesión', MessageType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'PruebaApp',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              obscureText: !_mostrarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarPassword = !_mostrarPassword;
                    });
                  },
                ),
              ),
            ),
            Column(
              children: quickUsers.map((user) {
                return ElevatedButton(
                  onPressed: () {
                    emailController.text = user['email']!;
                    passwordController.text = user['password']!;

                    iniciarSesion();
                  },
                  child: Text('Iniciar como ${user['email']}'),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: iniciarSesion,
              child: Text('Iniciar sesión'),
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                'Registrar nuevo usuario',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------- REGISTER PAGE ---------------------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _mostrarPassword = false;

  Future<void> registrarUsuario() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!validarEmail(email)) {
      mostrarMensaje(context, 'Ingresá un correo electrónico válido.', MessageType.failure);
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'Temp1234.',
      );

      await FirebaseAuth.instance.currentUser?.delete();

      if (!validarPassword(password)) {
        mostrarMensaje(
          context, 'La contraseña debe tener entre 8 y 20 caracteres e incluir una mayúscula, una minúscula, un número y un caracter especial.', MessageType.failure
        );
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      mostrarMensaje(context, '¡Registro exitoso!', MessageType.success);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        mostrarMensaje(context, 'El correo ya está registrado.', MessageType.failure);
      } else {
        mostrarMensaje(context, e.message ?? 'Error al registrar', MessageType.failure);
      }
    }
  }

  bool validarEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool validarPassword(String password) {
    final RegExp passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[.,:;!?@#%\-_]).{8,20}$');
    return passwordRegex.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar nuevo usuario")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              obscureText: !_mostrarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarPassword = !_mostrarPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registrarUsuario,
              child: Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}



// --------------------- SESSION PAGE ---------------------
class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {

  void logOut() {
    Session.activeUser = '';
    Navigator.pushNamed(context, '/');
    mostrarMensaje(context, 'Se ha cerrado la sesión', MessageType.warning);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'PruebaApp',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                'Hola, ${Session.activeUser}. Bienvenido a PruebaApp;',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Session {
  static var sessionPage = _SessionPageState();
  static String? activeUser;
  static int inactiveSessionTimer = 0;
  static const int sessionTimeLimit = 300;

  static void startCountdown() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      inactiveSessionTimer++;
      print('Timer: $timer');

      if (inactiveSessionTimer >= sessionTimeLimit) {
        timer.cancel();
        sessionPage.logOut();
      }
    });
  }
}