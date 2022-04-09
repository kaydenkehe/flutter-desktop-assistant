// ICON CREDIT: https://www.flaticon.com/free-icons/mic Mic icons created by Dave Gandy - Flaticon

import 'package:math_expressions/math_expressions.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

// Colors
var textColor = const Color(0xFFFFFFFF);
var backgroundColor = const Color(0xFF23262B);
var backgroundColorDark = const Color(0xFF1A1C21);
var activeColor = const Color(0xFFFFCB74);

var buttonColors = WindowButtonColors (
  iconNormal: activeColor,
  mouseOver: backgroundColorDark,
  mouseDown: backgroundColorDark,
  iconMouseOver: activeColor,
  iconMouseDown: activeColor
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  windowManager.ensureInitialized();
  Window.initialize();
  await Window.setEffect(effect: WindowEffect.transparent);

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    windowManager.show();
  });

  await GetStorage.init();
  if (storage.read('commands') == null) {
    storage.write('commands', <String, String> {});
  }

  DartVLC.initialize();
  runApp(const App());

  doWhenWindowReady(() {
    const initialSize = Size(500, 500);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.maxSize = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Dexter';
    appWindow.show();
  });
}

final storage = GetStorage();

class App extends StatelessWidget {
  const App({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp (
      theme: ThemeData (
        fontFamily: 'Comfortaa',
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Home(),
        '/commands': (context) => const Commands(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isKeyPressed = false;
  String command = '';
  String message = '';
  FlutterTts flutterTts = FlutterTts();
  Player player = Player(id: 1);
  TextEditingController interpreterController = TextEditingController();
  TextEditingController directoryController = TextEditingController();
  TextEditingController commandController = TextEditingController();
  TextEditingController scriptController = TextEditingController();
  Color homeBackgroundColor = backgroundColor;
  bool progressVisible = false;

  recordAudio() async {
    if ((storage.read('interpreter') != null) && (storage.read('directory') != null)) {
      setState(() {
        progressVisible = true;
      });
      var sttResult = await Process.run(storage.read('interpreter'), [storage.read('directory') + 'stt.py']);
      command = sttResult.stdout.trim();

      Map commands = storage.read('commands');
      if (commands.keys.toList().contains(command) ) {
        var commandResult = await Process.run(storage.read('interpreter'), [storage.read('directory') + commands[command]]);
        setState(() {
          command = command;
          message = commandResult.stdout.trim();          
        });
      } else if (command.contains('what is')) {
        String commandTrim = command.replaceAll('what is', '').trim();
        ContextModel cm = ContextModel();
        Parser p = Parser();
        Expression exp = p.parse(commandTrim);
        double answer = exp.evaluate(EvaluationType.REAL, cm);
        message = answer % 1 == 0 ? answer.toInt().toString() : answer.toStringAsFixed(2).toString();
      } else {
        message = "Sorry, I don't know that";
      }

      await playTTS(message);
      setState(() {
        progressVisible = false;
      });
    }
    isKeyPressed = false;
  }

  playTTS(String message) async {
    var process = await Process.start(storage.read('interpreter'), [storage.read('directory') + 'tts.py']);
    process.stdin.writeln(message);
    process.stdin.writeln(storage.read('directory'));
    await process.exitCode;

    player.open (
      Playlist(
        medias: [
          Media.file(File(storage.read('directory') + 'tts.mp3')),
        ],
      ),
      autoStart: true
    );
    player.play();
  }

  setInterpreter() {
    storage.write('interpreter', interpreterController.text);
  }

  setDirectory() {
    storage.write('directory', directoryController.text);
  }

  addCommand(BuildContext context) {
    showDialog (
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return AlertDialog (
          elevation: 10.0,
          backgroundColor: backgroundColorDark,
          content: Column (
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField (
                controller: commandController,
                style: TextStyle (
                  fontSize: 14.0,
                  color: activeColor
                ),
                decoration: InputDecoration (
                  enabledBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  isDense: true,
                  labelText: 'Command',
                  labelStyle: TextStyle (
                    color: textColor
                  )
                ),
              ),
              const SizedBox(height: 10.0),
              TextField (
                controller: scriptController,
                style: TextStyle (
                  fontSize: 14.0,
                  color: activeColor
                ),
                decoration: InputDecoration (
                  enabledBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  isDense: true,
                  labelText: 'Script Name',
                  labelStyle: TextStyle (
                    color: textColor,
                  )
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text (
                'Add',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () {
                var commandMap = storage.read('commands');
                commandMap[commandController.text] = scriptController.text;
                storage.write('commands', commandMap);
                scriptController.text = '';
                commandController.text = '';
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
  }

  @override
  void initState() {
    if (storage.read('interpreter') != null) {
      interpreterController.text = storage.read('interpreter');
    } else {
      interpreterController.text = '';
    }
    if (storage.read('directory') != null) {
      directoryController.text = storage.read('directory');
    } else {
      directoryController.text = '';
    }

    super.initState();
  }

  showMenuSheet(context) {
    showModalBottomSheet (
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      constraints: const BoxConstraints (
        maxWidth: 470      
      ),
      backgroundColor: backgroundColor,
      context: context,
      builder: (BuildContext context) {
        return Column (
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect (
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              child: Container (
                color: backgroundColorDark,
                padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0, bottom: 20.0),
                child: Column (
                  children: [
                    SizedBox (
                      width: double.infinity,
                      child: Text (
                        'Menu',
                        textAlign: TextAlign.left,
                        style: TextStyle (
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                          fontSize: 20.0,
                        )
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Row (
                      children: [
                        Icon (
                          Icons.folder,
                          color: activeColor,
                          size: 20.0
                        ),
                        const SizedBox(width: 10.0),
                        Text (
                          'Python Interpreter',
                          style: TextStyle (
                            color: textColor,
                            fontSize: 15.0,
                          )
                        ),
                        const SizedBox(width: 10.0),
                        Expanded (
                          child: TextField (
                            cursorColor: textColor,
                            controller: interpreterController,
                            style: TextStyle (
                              fontSize: 10.0,
                              color: textColor,
                            ),
                            decoration: InputDecoration (
                              suffixIcon: IconButton (
                                icon: Icon (
                                  Icons.arrow_right_rounded,
                                  color: activeColor,
                                ),
                                color: activeColor,
                                onPressed: () => setInterpreter(),
                              ),
                              isDense: true,
                              labelText: 'Path',
                              labelStyle: TextStyle (
                                color: activeColor
                              ),
                              focusedBorder: OutlineInputBorder (
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                borderSide: BorderSide (
                                  width: 3.0,
                                  style: BorderStyle.solid,
                                  color: activeColor,
                                )
                              ),
                              enabledBorder: OutlineInputBorder (
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                borderSide: BorderSide (
                                  width: 3.0,
                                  style: BorderStyle.solid,
                                  color: activeColor,
                                )
                              ),
                            ),
                          ),
                        ),
                      ]
                    ),
                    const SizedBox(height: 14.0),
                    Row (
                      children: [
                        Icon (
                          Icons.code,
                          color: activeColor,
                          size: 20.0
                        ),
                        const SizedBox(width: 10.0),
                        Text (
                          'Script Directory',
                          style: TextStyle (
                            color: textColor,
                            fontSize: 15.0,
                          )
                        ),
                        const SizedBox(width: 10.0),
                        Expanded (
                          child: TextField (
                            cursorColor: textColor,
                            controller: directoryController,
                            style: TextStyle (
                              fontSize: 10.0,
                              color: textColor,
                            ),
                            decoration: InputDecoration (
                              suffixIcon: IconButton (
                                icon: Icon (
                                  Icons.arrow_right_rounded,
                                  color: activeColor,
                                ),
                                color: activeColor,
                                onPressed: () => setDirectory(),
                              ),
                              isDense: true,
                              labelText: 'Path',
                              labelStyle: TextStyle (
                                color: activeColor
                              ),
                              focusedBorder: OutlineInputBorder (
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                borderSide: BorderSide (
                                  width: 3.0,
                                  style: BorderStyle.solid,
                                  color: activeColor,
                                )
                              ),
                              enabledBorder: OutlineInputBorder (
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                borderSide: BorderSide (
                                  width: 3.0,
                                  style: BorderStyle.solid,
                                  color: activeColor,
                                )
                              ),
                            ),
                          ),
                        ),
                      ]
                    ),
                    const SizedBox(height: 14.0),
                    Row (
                      children: [
                        Icon (
                          Icons.my_library_add_rounded,
                          color: activeColor,
                          size: 20.0
                        ),
                        const SizedBox(width: 10.0),
                        Text (
                          'Add Command',
                          style: TextStyle (
                            color: textColor,
                            fontSize: 15.0,
                          )
                        ),
                        const SizedBox(width: 10.0),
                        SizedBox (
                          width: 55,
                          height: 35,
                          child: ElevatedButton (
                            onPressed: () => addCommand(context),
                            style: ButtonStyle (
                              backgroundColor: MaterialStateProperty.all(activeColor),
                              elevation: MaterialStateProperty.all(0.0),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)
                              ),
                            )),
                            child: Icon (
                              Icons.add,
                              color: backgroundColorDark,
                              size: 20.0,
                            ),
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Row (
                      children: [
                        Icon (
                          Icons.edit,
                          color: activeColor,
                          size: 20.0
                        ),
                        const SizedBox(width: 10.0),
                        Text (
                          'Edit Existing Commands',
                          style: TextStyle (
                            color: textColor,
                            fontSize: 15.0,
                          )
                        ),
                        const SizedBox(width: 10.0),
                        SizedBox (
                          width: 60,
                          height: 35,
                          child: ElevatedButton (
                            onPressed: () {
                              Navigator.of(context).pushNamed('/commands');
                            },
                            style: ButtonStyle (
                              backgroundColor: MaterialStateProperty.all(activeColor),
                              elevation: MaterialStateProperty.all(0.0),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)
                              ),
                            )),
                            child: Icon (
                              Icons.arrow_right_alt_rounded,
                              color: backgroundColorDark,
                              size: 20.0,
                            ),
                          )
                        ),
                      ]
                    ),
                  ]
                ),
              ),
            ),
            SizedBox (
              width: double.infinity,
              height: 15.0,
              child: Container (
                color: backgroundColor,
              )
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect (
      borderRadius: BorderRadius.circular(10.0),
      child: RawKeyboardListener (
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) async {
          if ((event.isKeyPressed(LogicalKeyboardKey.f5)) && (isKeyPressed == false)) {
            isKeyPressed = true;
            await recordAudio();
          }
        },
        child: Scaffold (
          backgroundColor: Colors.transparent,
          body: Container (
            height: double.infinity,
            color: homeBackgroundColor,
            child: Column (
              mainAxisSize: MainAxisSize.max,
              children: [
                WindowTitleBarBox(
                  child: Row (
                    children: [
                      IconButton (
                        icon: Icon (
                          Icons.menu,
                          color: activeColor
                        ),
                        onPressed: () => showMenuSheet(context),
                      ),
                      Expanded (
                        child: MoveWindow (),
                      ),
                      Row (
                        children: [
                          MinimizeWindowButton(colors: buttonColors),
                          CloseWindowButton(colors: buttonColors)
                        ],
                      )
                    ]
                  )
                ),
                Align (
                  alignment: Alignment.topCenter,
                  child: AutoSizeText (
                    command,
                    style: TextStyle (
                      color: textColor,
                      fontSize: 30.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                  )
                ),
                Expanded (
                  child: Stack (
                    children: [
                      Center (
                        child: Icon (
                          Icons.mic,
                          size: 250.0,
                          color: activeColor
                        )  
                      ),
                      Center (
                        child: Visibility (
                          visible: progressVisible,
                          child: TweenAnimationBuilder (
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 4),
                            builder: (context, double value, _) => SizedBox (
                              height: 325.0,
                              width: 325.0,
                              child: CircularProgressIndicator (
                                value: value,
                                color: activeColor,
                                backgroundColor: textColor,
                                strokeWidth: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center (
                        child: Visibility (
                          visible: !progressVisible,
                          child: TweenAnimationBuilder (
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 0),
                            builder: (context, double value, _) => SizedBox (
                              height: 325.0,
                              width: 325.0,
                              child: CircularProgressIndicator (
                                value: value,
                                color: textColor,
                                backgroundColor: textColor,
                                strokeWidth: 20.0,
                              ),
                            ),
                          ),
                        ),
                      )
                    ]
                  )
                ),
                Container (
                  margin: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
                  child: Align (
                    alignment: Alignment.bottomCenter,
                    child: AutoSizeText (
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle (
                        color: textColor,
                        fontSize: 30.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                    )
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}

class Commands extends StatefulWidget {
  const Commands({ Key? key }) : super(key: key);

  @override
  State<Commands> createState() => _CommandsState();
}

class _CommandsState extends State<Commands> {
  late Map commands;
  TextEditingController commandController = TextEditingController();
  TextEditingController scriptController = TextEditingController();

  editCommand(BuildContext context, String commandName, String scriptName) {
    commandController.text = commandName;
    scriptController.text = scriptName;
    showDialog (
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return AlertDialog (
          elevation: 10.0,
          backgroundColor: backgroundColorDark,
          content: Column (
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField (
                controller: commandController,
                style: TextStyle (
                  fontSize: 14.0,
                  color: activeColor
                ),
                decoration: InputDecoration (
                  enabledBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  isDense: true,
                  labelText: 'Command',
                  labelStyle: TextStyle (
                    color: textColor
                  )
                ),
              ),
              const SizedBox(height: 10.0),
              TextField (
                controller: scriptController,
                style: TextStyle (
                  fontSize: 14.0,
                  color: activeColor
                ),
                decoration: InputDecoration (
                  enabledBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder (
                    borderSide: BorderSide (
                      color: textColor, 
                      width: 1.0, 
                      style: BorderStyle.solid
                    ),
                  ),
                  isDense: true,
                  labelText: 'Script Name',
                  labelStyle: TextStyle (
                    color: textColor
                  )
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text (
                'Add',
                style: TextStyle (
                  color: activeColor
                )
              ),
              onPressed: () {
                var commandMap = storage.read('commands');
                commandMap.removeWhere((k, v) => k == commandName);
                commandMap[commandController.text] = scriptController.text;
                storage.write('commands', commandMap);
                scriptController.text = '';
                commandController.text = '';
                Navigator.of(context).pop();
                setState(() {
                  commands = commandMap;
                });
              },
            ),
          ],
        );
      }
    );
  }

  @override
  void initState() {
    commands = storage.read('commands');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect (
      borderRadius: BorderRadius.circular(10.0),
      child: Scaffold (
          backgroundColor: Colors.transparent,
          body: Container (
            color: backgroundColor,
            child: Column (
              children: [
                WindowTitleBarBox(
                  child: Row (
                    children: [
                      IconButton (
                        icon: Icon (
                          Icons.arrow_back,
                          color: activeColor
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
                        },
                      ),
                      Expanded (
                        child: MoveWindow (),
                      ),
                      Row (
                        children: [
                          MinimizeWindowButton(colors: buttonColors),
                          CloseWindowButton(colors: buttonColors)
                        ],
                      )
                    ]
                  )
                ),
                Expanded (
                child: Container (
                  margin: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration (
                    color: backgroundColorDark,
                    border: Border.all (
                      color: backgroundColor,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(10))
                  ),
                  child: Container (
                    margin: const EdgeInsets.only(right: 8.0, top: 20.0, bottom: 20.0),
                    child: RawScrollbar (
                      thumbColor: textColor,
                      radius: const Radius.circular(5.0),
                      isAlwaysShown: true,
                      child: ScrollConfiguration (
                        behavior: RemoveGlow(),
                        child: ListView (
                          children: [
                            Align (
                              alignment: Alignment.topCenter,
                              child: Text (
                                'Commands',
                                style: TextStyle (
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                  fontSize: 28.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 17.0),
                            for (String command in commands.keys)
                            Container (
                              margin: const EdgeInsets.only(left: 10.0),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row (
                                children: [
                                  Text (
                                    command,
                                    style: TextStyle (
                                      color: textColor,
                                      fontSize: 23.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton (
                                    onPressed: () {
                                      editCommand(context, command, commands[command]);
                                    },
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue[500],
                                    iconSize: 25.0,
                                  ),
                                  IconButton (
                                    onPressed: () {
                                      setState(() {
                                        commands.removeWhere((k, v) => k == command);
                                        storage.write('commands', commands);
                                      });
                                    },
                                    icon: const Icon(Icons.not_interested_rounded),
                                    color: Colors.red[500],
                                    iconSize: 25.0,
                                  )
                                ]
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ]
            )
          )
      ),
    );
  }
}

// https://stackoverflow.com/questions/51119795/how-to-remove-scroll-glow
class RemoveGlow extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator (
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
