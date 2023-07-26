import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roquiz/persistence/QuestionRepository.dart';
import 'package:roquiz/persistence/Settings.dart';
import 'package:roquiz/model/Themes.dart';
import 'package:roquiz/widget/change_theme_button_widget.dart';
import 'package:roquiz/widget/confirmation_alert.dart';
import 'package:roquiz/widget/icon_button_widget.dart';

class ViewSettings extends StatefulWidget {
  const ViewSettings({
    Key? key,
    required this.qRepo,
    required this.settings,
    required this.saveSettings,
  }) : super(key: key);

  final QuestionRepository qRepo;
  final Settings settings;
  final Function(int, int, bool, bool, bool) saveSettings;

  @override
  State<StatefulWidget> createState() => ViewSettingsState();
}

class ViewSettingsState extends State<ViewSettings> {
  int _questionNumber = Settings.DEFAULT_QUESTION_NUMBER;
  int _timer = Settings.DEFAULT_TIMER;
  bool _shuffleAnswers = Settings.DEFAULT_SHUFFLE_ANSWERS;
  bool _confirmAlerts = Settings.DEFAULT_CONFIRM_ALERTS;
  bool _darkTheme = Settings.DEFAULT_DARK_THEME; // previous value

  void _resetQuestionNumber() {
    setState(() => _questionNumber = Settings.DEFAULT_QUESTION_NUMBER);
  }

  void _increaseQuestionNumber(int v) {
    setState(() {
      _questionNumber + v <= widget.qRepo.questions.length
          ? _questionNumber += v
          : _questionNumber = widget.qRepo.questions.length;
    });
  }

  void _decreaseQuestionNumber(int v) {
    setState(() {
      _questionNumber - v >= Settings.DEFAULT_QUESTION_NUMBER / 2
          ? _questionNumber -= v
          : _questionNumber = Settings.DEFAULT_QUESTION_NUMBER ~/ 2;
    });
  }

  void _resetTimer() {
    setState(() => _timer = Settings.DEFAULT_TIMER);
  }

  void _increaseTimer(int v) {
    setState(() {
      _timer + v <= widget.qRepo.questions.length * 2
          ? _timer += v
          : _timer = widget.qRepo.questions.length * 2;
    });
  }

  void _decreaseTimer(int v) {
    setState(() {
      _timer - v >= Settings.DEFAULT_TIMER / 2
          ? _timer -= v
          : _timer = Settings.DEFAULT_TIMER ~/ 2;
    });
  }

  void _resetShuffleAnswers() {
    setState(() => _shuffleAnswers = Settings.DEFAULT_SHUFFLE_ANSWERS);
  }

  void _selectShuffleAnswers(bool value) {
    setState(() {
      _shuffleAnswers = value;
    });
  }

  void _resetConfirmAlerts() {
    setState(() => _confirmAlerts = Settings.DEFAULT_CONFIRM_ALERTS);
  }

  void _selectConfirmAlerts(bool value) {
    setState(() {
      _confirmAlerts = value;
    });
  }

  void _resetTheme(ThemeProvider themeProvider) {
    setState(() {
      themeProvider.toggleTheme(Settings.DEFAULT_DARK_THEME);
    });
  }

  void _reset(ThemeProvider themeProvider) {
    _resetQuestionNumber();
    _resetTimer();
    _resetShuffleAnswers();
    _resetConfirmAlerts();
    _resetTheme(themeProvider);
  }

  bool _isDefault(ThemeProvider themeProvider) {
    return _questionNumber == Settings.DEFAULT_QUESTION_NUMBER &&
        _timer == Settings.DEFAULT_TIMER &&
        _shuffleAnswers == Settings.DEFAULT_SHUFFLE_ANSWERS &&
        _confirmAlerts == Settings.DEFAULT_CONFIRM_ALERTS &&
        themeProvider.isDarkMode == Settings.DEFAULT_DARK_THEME;
  }

  bool _isChanged(ThemeProvider themeProvider) {
    return _questionNumber != widget.settings.questionNumber ||
        _timer != widget.settings.timer ||
        _shuffleAnswers != widget.settings.shuffleAnswers ||
        _confirmAlerts != widget.settings.confirmAlerts ||
        themeProvider.isDarkMode != widget.settings.darkTheme;
  }

  void _showConfirmationDialog(BuildContext context, String title,
      String content, void Function()? onConfirm, void Function()? onCancel) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmationAlert(
              title: title,
              content: content,
              onConfirm: onConfirm,
              onCancel: onCancel);
        });
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _questionNumber = widget.settings.questionNumber;
      _timer = widget.settings.timer;
      _shuffleAnswers = widget.settings.shuffleAnswers;
      _confirmAlerts = widget.settings.confirmAlerts;
      _darkTheme = widget.settings.darkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return WillPopScope(
      onWillPop: () async {
        if (_isChanged(themeProvider) && widget.settings.confirmAlerts) {
          _showConfirmationDialog(
            context,
            "Modifiche Non Salvate",
            "Uscire senza salvare?",
            () {
              // Discard
              Navigator.pop(context);
              Navigator.pop(context);
              themeProvider.toggleTheme(_darkTheme);
            },
            () {
              Navigator.pop(context);
            },
          );
        } else {
          themeProvider.toggleTheme(_darkTheme);
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Impostazioni"),
          centerTitle: true,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_isChanged(themeProvider) && widget.settings.confirmAlerts) {
                _showConfirmationDialog(
                  context,
                  "Modifiche Non Salvate",
                  "Uscire senza salvare?",
                  () {
                    // Discard (Confirm)
                    Navigator.pop(context);
                    Navigator.pop(context);
                    themeProvider.toggleTheme(_darkTheme);
                  },
                  () {
                    Navigator.pop(context);
                  },
                );
              } else {
                Navigator.pop(context);
                themeProvider.toggleTheme(_darkTheme);
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Center(
            child: ListView(
              shrinkWrap: true,
              children: [
                // SETTING: QUIZ QUESTION NUMBER
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onDoubleTap: () {
                            _resetQuestionNumber();
                          },
                          child: const Text("Numero domande per quiz: ",
                              style: TextStyle(fontSize: 20))),
                    ),
                    // DECREASE QUESTION NUMBER
                    IconButtonLongPressWidget(
                      onUpdate: () {
                        _decreaseQuestionNumber(1);
                      },
                      lightPalette: MyThemes.lightIconButtonPalette,
                      darkPalette: MyThemes.darkIconButtonPalette,
                      width: 40.0,
                      height: 40.0,
                      icon: Icons.remove,
                      iconSize: 35,
                    ),
                    // POOL SIZE COUNTER
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Container(
                        alignment: Alignment.center,
                        width: 35.0,
                        child: Text("$_questionNumber",
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    // INCREASE POOL SIZE
                    IconButtonLongPressWidget(
                      onUpdate: () {
                        _increaseQuestionNumber(1);
                      },
                      lightPalette: MyThemes.lightIconButtonPalette,
                      darkPalette: MyThemes.darkIconButtonPalette,
                      width: 40.0,
                      height: 40.0,
                      icon: Icons.add,
                      iconSize: 35,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // SETTING: TIMER
                Row(children: [
                  Expanded(
                    child: InkWell(
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onDoubleTap: () {
                          _resetTimer();
                        },
                        child: const Text("Timer (minuti): ",
                            style: TextStyle(fontSize: 20))),
                  ),
                  // DECREASE TIMER
                  IconButtonLongPressWidget(
                    onUpdate: () {
                      _decreaseTimer(1);
                    },
                    lightPalette: MyThemes.lightIconButtonPalette,
                    darkPalette: MyThemes.darkIconButtonPalette,
                    width: 40.0,
                    height: 40.0,
                    icon: Icons.remove,
                    iconSize: 35,
                  ),
                  // TIMER COUNTER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Container(
                      alignment: Alignment.center,
                      width: 35.0,
                      child:
                          Text("$_timer", style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  // INCREASE TIMER
                  IconButtonLongPressWidget(
                    onUpdate: () {
                      _increaseTimer(1);
                    },
                    lightPalette: MyThemes.lightIconButtonPalette,
                    darkPalette: MyThemes.darkIconButtonPalette,
                    width: 40.0,
                    height: 40.0,
                    icon: Icons.add,
                    iconSize: 35,
                  ),
                ]),

                const SizedBox(height: 20),
                // SETTING: SHUFFLE ANSWERS
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onDoubleTap: () {
                            _resetShuffleAnswers();
                          },
                          child: const Text("Mescola risposte: ",
                              style: TextStyle(fontSize: 20))),
                    ),
                    SizedBox(
                        width: 120.0,
                        child: Transform.scale(
                          scale: 1.5,
                          child: Checkbox(
                              value: _shuffleAnswers,
                              onChanged: (bool? value) =>
                                  _selectShuffleAnswers(value!)),
                        ))
                  ],
                ),
                const SizedBox(height: 20),
                // SETTING: CONFIRM ALERTS
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onDoubleTap: () {
                            _resetConfirmAlerts();
                          },
                          child: const Text("Alert di conferma: ",
                              style: TextStyle(fontSize: 20))),
                    ),
                    SizedBox(
                        width: 120.0,
                        child: Transform.scale(
                          scale: 1.5,
                          child: Checkbox(
                              value: _confirmAlerts,
                              onChanged: (bool? value) =>
                                  _selectConfirmAlerts(value!)),
                        ))
                  ],
                ),
                const SizedBox(height: 20),
                // SETTING: DARK THEME
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onDoubleTap: () {
                            _resetTheme(themeProvider);
                          },
                          child: const Text("Tema scuro: ",
                              style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(
                      width: 120.0,
                      child: ChangeThemeButtonWidget(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(
              Icons.refresh,
              size: 40.0,
            ),
            onPressed: _isDefault(themeProvider)
                ? null
                : () {
                    _reset(themeProvider);
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            label: const Text(
              "Ripristina",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // BUTTONS: Save, Cancel
        persistentFooterButtons: [
          Row(
            children: [
              FittedBox(
                fit: BoxFit.fitWidth,
                child: ElevatedButton(
                  onPressed: () {
                    widget.saveSettings(
                        _questionNumber,
                        _timer,
                        _shuffleAnswers,
                        _confirmAlerts,
                        themeProvider.isDarkMode);
                    _darkTheme = themeProvider.isDarkMode;

                    Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 50.0,
                    width: 100.0,
                    child: const Text(
                      "Salva",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 5),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: ElevatedButton(
                  onPressed: () {
                    themeProvider.toggleTheme(_darkTheme);

                    Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 50.0,
                    width: 100.0,
                    child: const Text(
                      "Cancella",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
