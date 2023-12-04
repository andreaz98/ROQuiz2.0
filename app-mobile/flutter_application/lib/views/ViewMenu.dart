import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:roquiz/model/AppUpdater.dart';
import 'package:roquiz/model/Question.dart';
import 'package:roquiz/model/Utils.dart';
import 'package:roquiz/persistence/QuestionRepository.dart';
import 'package:roquiz/persistence/Settings.dart';
import 'package:roquiz/views/ViewQuiz.dart';
import 'package:roquiz/views/ViewSettings.dart';
import 'package:roquiz/views/ViewTopics.dart';
import 'package:roquiz/views/ViewInfo.dart';
import 'package:roquiz/model/Themes.dart';
import 'package:roquiz/widget/confirmation_alert.dart';
import 'package:roquiz/widget/icon_button_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ViewMenu extends StatefulWidget {
  const ViewMenu({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ViewMenuState();
}

class ViewMenuState extends State<ViewMenu> {
  final QuestionRepository qRepo = QuestionRepository();

  String _qRepoLoadingError = "";

  final Settings _settings = Settings();
  bool _topicsPresent = false;
  final List<bool> _selectedTopics = [];
  int _quizPool = 0;

  void loadTopics() {
    setState(() {
      _selectedTopics.clear();
      _topicsPresent = qRepo.topicsPresent;
      if (_topicsPresent) {
        _quizPool = 0;
        for (int i = 0; i < qRepo.topics.length; i++) {
          _selectedTopics.add(true);
          _quizPool += qRepo.qNumPerTopic[i];
        }
      } else {
        _quizPool = qRepo.questions.length;
      }
    });
  }

  List<Question> _getPoolFromSelected() {
    List<Question> res = [];
    if (_topicsPresent) {
      for (int i = 0, j = 0; i < _selectedTopics.length; i++) {
        if (_selectedTopics[i]) {
          for (int k = 0; k < qRepo.getQuestionNumPerTopic()[i]; j++, k++) {
            res.add(qRepo.getQuestions()[j]);
          }
        } else {
          j += qRepo.getQuestionNumPerTopic()[i];
        }
      }
    } else {
      res = qRepo.questions;
    }

    return res;
  }

  void updateQuizPool(int v) {
    setState(() {
      _quizPool = v;
    });
  }

  void saveSettings(bool? appUpdateCheck, bool? questionsUpdateCheck, int? qNum,
      int? timer, bool? shuffle, bool? confirmAlerts, bool? dTheme) {
    setState(() {
      if (appUpdateCheck != null) {
        _settings.checkAppUpdate = appUpdateCheck;
      }
      if (questionsUpdateCheck != null) {
        _settings.checkQuestionsUpdate = questionsUpdateCheck;
      }
      if (qNum != null) {
        _settings.questionNumber = qNum;
      }
      if (timer != null) {
        _settings.timer = timer;
      }
      if (shuffle != null) {
        _settings.shuffleAnswers = shuffle;
      }
      if (confirmAlerts != null) {
        _settings.confirmAlerts = confirmAlerts;
      }
      if (dTheme != null) {
        _settings.darkTheme = dTheme;
      }
      _settings.saveToSharedPreferences();
      loadTopics();
    });
  }

  void _showConfirmationDialog(BuildContext context, String title,
      String content, void Function()? onConfirm, void Function()? onCancel) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmationAlert(
              title: title,
              content: content,
              buttonConfirmText: "Sì",
              buttonCancelText: "No",
              onConfirm: onConfirm,
              onCancel: onCancel);
        });
  }

  Future<void> _launchInBrowser(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _checkNewVersionDialog(bool newVersionPresent, String newVersion,
      String newVersionDownloadURL) async {
    if (newVersionPresent) {
      _showConfirmationDialog(
        context,
        "Nuova Versione App",
        "È stata trovata una versione più recente dell'applicazione.\n"
            "Versione attuale: v${Settings.VERSION_NUMBER}\n"
            "Nuova versione: $newVersion\n"
            "Scaricare la nuova versione?",
        () {
          _launchInBrowser(newVersionDownloadURL);
          Navigator.pop(context);
        },
        () => Navigator.pop(context),
      );
    }
  }

  Future<void> _checkNewQuestionsDialog(
      bool newQuestionsPresent, DateTime date, int questionNumber) async {
    if (newQuestionsPresent) {
      _showConfirmationDialog(
        context,
        "Nuove Domande",
        "È stata trovata una versione più recente del file contenente le domande.\n"
            "Versione attuale: ${qRepo.questions.length} domande (${Utils.getParsedDateTime(qRepo.lastQuestionUpdate)}).\n"
            "Nuova versione: $questionNumber domande (${Utils.getParsedDateTime(date)}).\n"
            "Scaricare il nuovo file?",
        () {
          setState(() {
            qRepo.update().then((_) => updateQuizPool(qRepo.questions.length));
            _quizPool = qRepo.questions.length;
          });
          Navigator.pop(context);
        },
        () => Navigator.pop(context),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _settings.loadFromSharedPreferences();

    qRepo
        .load()
        .then(
          (_) => {
            loadTopics(),
            setState(
              () {
                _topicsPresent = qRepo.hasTopics();
              },
            )
          },
        )
        .onError((error, stackTrace) =>
            {setState(() => _qRepoLoadingError = error.toString())});

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() => Settings.VERSION_NUMBER = packageInfo.version);

      if (_settings.checkAppUpdate) {
        AppUpdater.checkNewVersion(Settings.VERSION_NUMBER).then((result) {
          _checkNewVersionDialog(result.$1, result.$2, result.$3);
        }).onError((error, stackTrace) {
          print("Error: $stackTrace");
        });
      }
      if (_settings.checkQuestionsUpdate) {
        qRepo.checkQuestionUpdates().then((result) {
          _checkNewQuestionsDialog(result.$1, result.$2, result.$3);
        }).onError((error, stackTrace) {
          print("Error: $error");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Settings.SHOW_APP_LOGO
                      ? Column(children: [
                          SvgPicture.asset(
                            'assets/icons/logo.svg',
                            alignment: Alignment.center,
                            fit: BoxFit.fitWidth,
                            width: 200,
                            colorFilter: ColorFilter.mode(
                                themeProvider.isDarkMode
                                    ? Colors.indigo[300]!
                                    : Colors.indigo[600]!,
                                BlendMode.srcIn),
                          ),
                          const Text(
                            Settings.APP_TITLE,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ])
                      : const Text(
                          Settings.APP_TITLE,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  Text(
                    "v${Settings.VERSION_NUMBER}",
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(flex: 1),
                  // BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: qRepo.questions.isEmpty ||
                                qRepo.questions.length <
                                    _settings.questionNumber
                            ? null
                            : () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ViewQuiz(
                                              questions: _getPoolFromSelected(),
                                              settings: _settings,
                                            )));
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            "Avvia",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _topicsPresent
                            ? () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ViewTopics(
                                              qRepo: qRepo,
                                              settings: _settings,
                                              updateQuizPool: updateQuizPool,
                                              selectedTopics: _selectedTopics,
                                            )));
                              }
                            : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            "Argomenti",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(direction: Axis.horizontal, children: [
                    const Icon(
                      Icons.format_list_numbered_rounded,
                    ),
                    Text(" Domande: ${_settings.questionNumber} su $_quizPool"),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.timer_rounded,
                    ),
                    Text(" Tempo: ${_settings.timer} min"),
                  ]),
                  _qRepoLoadingError.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            _qRepoLoadingError,
                            style: const TextStyle(color: Colors.red),
                          ))
                      : const SizedBox(height: 50),
                  InkWell(
                    onTap: () {
                      _launchInBrowser("https://github.com/mikyll/ROQuiz");
                    },
                    child: Container(
                      color: Colors.indigo.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                            "Se l'app ti è piaciuta, considera di lasciare una stellina alla repository GitHub!\n\nBasta un click qui!",
                            maxLines: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                            )),
                      ),
                    ),
                  ),
                  const Spacer(flex: 5),
                ],
              ))),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButtonWidget(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewSettings(
                            qRepo: qRepo,
                            settings: _settings,
                            saveSettings: saveSettings,
                            reloadTopics: loadTopics,
                          )));
            },
            width: 60.0,
            height: 60.0,
            lightPalette: MyThemes.lightIconButtonPalette,
            darkPalette: MyThemes.darkIconButtonPalette,
            icon: Icons.settings,
            iconSize: 40,
            shadow: true,
          ),
          const SizedBox(height: 10.0),
          IconButtonWidget(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewInfo(settings: _settings)));
            },
            width: 60.0,
            height: 60.0,
            lightPalette: MyThemes.lightIconButtonPalette,
            darkPalette: MyThemes.darkIconButtonPalette,
            icon: Icons.info,
            iconSize: 40,
            shadow: true,
          ),
        ],
      ),
    );
  }
}
