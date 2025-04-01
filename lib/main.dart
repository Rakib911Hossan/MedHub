import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_project/screen/login_screen.dart';
import 'package:new_project/screen/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern Pharmacy',
      theme: ThemeData(
        primaryColor: const Color(0xFF14cbea),
        scaffoldBackgroundColor: const Color(0xFFf5f5f5),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0a6979)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF343c3c)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF31B8CF),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF04A3BE),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Hub'),
        centerTitle: true,
        backgroundColor: const Color(0xFF04A3BE),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              // Exit the app
              _showExitDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 30, left: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Table for Name and ID Alignment (No Padding, Font Size 12)
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2), // Adjust width for names
                  1: FlexColumnWidth(1), // Adjust width for IDs
                },
                children: const [
                  TableRow(children: [
                    Text('Rakib Hossan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('20235203073', style: TextStyle(fontSize: 12)),
                  ]),
                  TableRow(children: [
                    Text('Mahfuz Ali', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('20235203071', style: TextStyle(fontSize: 12)),
                  ]),
                  TableRow(children: [
                    Text('Akash Hossain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('20235203068', style: TextStyle(fontSize: 12)),
                  ]),
                  TableRow(children: [
                    Text('Labib Hasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('20235203037', style: TextStyle(fontSize: 12)),
                  ]),
                  TableRow(children: [
                    Text('Santo Mitro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text('20235203066', style: TextStyle(fontSize: 12)),
                  ]),
                ],
              ),

              // Logo Image
              Image.asset('lib/assets/v987-18a.jpg', height: 150),

              const SizedBox(height: 20),

              Text(
                'Welcome to Med Hub',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              SystemNavigator.pop(); // Exit app
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}