import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/log.dart';
import 'services/google_sheets_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _sheetIdController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedSheetId();
  }

  // 保存されたシートIDを読み込む
  Future<void> _loadSavedSheetId() async {
    final sheetId = await GoogleSheetsService.instance.getSavedSheetId();
    if (sheetId != null && sheetId.isNotEmpty) {
      setState(() {
        _sheetIdController.text = sheetId;
      });
    }
  }

  // GoogleシートのURLを開く
  void _openGoogleSheet() async {
    final url = GoogleSheetsService.instance.getSheetUrl();
    if (url.isEmpty) return;

    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  void _onLoginPressed() async {
    // ログインボタンが押されたときの処理をここに実装
    if (_sheetIdController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final sheetId = _sheetIdController.text;

      // Google Sheetsサービスを初期化
      final success = await GoogleSheetsService.instance.initialize(sheetId);

      setState(() {
        _isLoading = false;
      });

      if (!success) {
        setState(() {
          _errorMessage = 'Google Sheetへの接続に失敗しました。IDを確認してください。';
        });
        return;
      }

      // ログ画面に右からフェードインするアニメーションで遷移
      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LogScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_sheetIdController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Google Sheetを開く',
              onPressed: _openGoogleSheet,
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Google SheetのIDを入力してください',
                style: TextStyle(
                  color: Color(0xFFFF8080), // 薄めの赤色
                  fontSize: 16, // 1行で収まる程度の文字サイズ
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ID: '),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _sheetIdController,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.edit), // ペンマーク
                          hintText: 'Google SheetのIDを入力',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue.shade200, // 薄い青色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 角丸の四角
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                      ),
                      child: const Text('ログイン'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
