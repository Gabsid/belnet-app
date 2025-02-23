import 'dart:async';

import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
//import 'package:belnet_mobile/src/utils/is_darkmode.dart';
//import 'package:belnet_mobile/src/widget/belnet_divider.dart';
import 'package:belnet_mobile/src/widget/belnet_power_button.dart';
import 'package:belnet_mobile/src/widget/themed_belnet_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

void main() async {
  //Load settings
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.getInstance().initialize();
  Provider.debugCheckInvalidValueType = null;
  runApp(BelnetApp());
}

class BelnetApp extends StatefulWidget {
  @override
  State<BelnetApp> createState() => _BelnetAppState();
}

class _BelnetAppState extends State<BelnetApp> {
  // This widget is the root of your application.

  AppModel appModel = new AppModel();

  void _initAppTheme() async {
    appModel.darkTheme = await appModel.appPreference.getTheme();
  }

  @override
  void initState() {
    super.initState();
    _initAppTheme();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ChangeNotifierProvider<AppModel>.value(
      value: appModel,
      child: Consumer<AppModel>(builder: (context, value, child) {
        return MaterialApp(
          title: 'Belnet App',
          debugShowCheckedModeBanner: false,
          theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
          // (
          //   primarySwatch: Colors.teal,
          //   visualDensity: VisualDensity.adaptivePlatformDensity,
          // ),
          home: BelnetHomePage(),
        );
      }),
    );
  }
}

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage> {
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    double mHeight = MediaQuery.of(context).size.height;
    double mWidth = MediaQuery.of(context).size.width;
    final appModel = Provider.of<AppModel>(context);
    return Scaffold(
      key: key,
      resizeToAvoidBottomInset:
          false, //Prevents overflow when keyboard is shown
      body: Container(
        color: appModel.darkTheme ? Color(0xff242430) : Color(0xffF9F9F9),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                  width: double.infinity,
                  height: mHeight * 1.45 / 3,
                  // decoration: BoxDecoration(
                  //   boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.grey,
                  //     offset: Offset(0.0, 1.0), //(x,y)
                  //     blurRadius: 8.0,
                  //   ),
                  // ],
                  // ),
                  child: SvgPicture.asset(
                      appModel.darkTheme
                          ? 'assets/images/BG_world.svg'
                          : 'assets/images/bg_world_map_white.svg',
                      fit: BoxFit.cover,
                      height: mHeight * 1.5 / 3,
                      width: mHeight * 2.5 / 3)),
            ),
            Positioned(
              top: mHeight * 0.15 / 3,
              right: mHeight * 0.08 / 3,
              child: GestureDetector(
                onTap: () {
                  appModel.darkTheme = !appModel.darkTheme;
                },
                child: appModel.darkTheme
                    ? SvgPicture.asset('assets/images/dark_theme.svg')
                    : SvgPicture.asset('assets/images/light_theme.svg'),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ThemedBelnetLogo(),
                MyForm(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final exitInput = TextEditingController(text: Settings.getInstance().exitNode);
final dnsInput =
    TextEditingController(text: Settings.getInstance().upstreamDNS);

// Create a Form widget.
class MyForm extends StatefulWidget {
  @override
  MyFormState createState() {
    return MyFormState();
  }
}

class MyFormState extends State<MyForm> with SingleTickerProviderStateMixin {
  static final key = new GlobalKey<FormState>();
  StreamSubscription<bool> _isConnectedEventSubscription;
  bool isClick = false;

  AnimationController _animationController;
  Animation _animation;

  final List<String> exitItems = [
    '8zhrwu36op5y6kz51qbwzgde1wrnhzmf8y14u7whmaiao3njn11y.beldex',
    'exit1.beldex',
    'exit.beldex',
  ];
  String selectedValue =
      '8zhrwu36op5y6kz51qbwzgde1wrnhzmf8y14u7whmaiao3njn11y.beldex';

  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));
  }

  @override
  void dispose() {
    // _animationController.dispose();
    super.dispose();

    _isConnectedEventSubscription?.cancel();
  }

  Future toggleBelnet() async {
    //if(BelnetLib.isConnected)
    isClick = isClick ? false : true;
    if (mounted) setState(() {});

    if (BelnetLib.isConnected) {
      await BelnetLib.disconnectFromBelnet();
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance();
      settings.exitNode =
          selectedValue.trim().toString(); //exitInput.value.text.trim();
      settings.upstreamDNS = dnsInput.value.text.trim();

      final result = await BelnetLib.prepareConnection();
      if (result)
        BelnetLib.connectToBelnet(
            exitNode: settings.exitNode, upstreamDNS: settings.upstreamDNS);
    }
    //  animationFunction();
  }

  @override
  Widget build(BuildContext context) {
    String val = 'test ';
    final appModel = Provider.of<AppModel>(context);
    Color color = appModel.darkTheme ? Color(0xff292937) : Colors.white;
    double mHeight = MediaQuery.of(context).size.height;
    double mWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BelnetPowerButton(
          onPressed: toggleBelnet,
          isClick: isClick,
          animation: _animation,
          animationController: _animationController,
        ),
        ConnectingStatus(
          isConnect: BelnetLib.isConnected,
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: mHeight * 0.10 / 3, top: mHeight * 0.15 / 3),
              child: Text(
                'Exit Node',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.height * 0.08 / 3,
              right: MediaQuery.of(context).size.height * 0.10 / 3,
              top: MediaQuery.of(context).size.height * 0.06 / 3),
          child: Container(
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Padding(
                padding: const EdgeInsets.only(
                    left: 0.0, right: 6.0, top: 3.0, bottom: 3.0),
                child:
//                 DropdownButton<String>(
//                   isExpanded: true,
//                            value: selectedValue,
//                            style: const TextStyle(
//                            color: Colors.deepPurple, //<-- SEE HERE
//                            fontSize: 25,
//                            fontWeight: FontWeight.bold),
//                            onChanged: (String newValue) {
//                             setState(() {
//                              selectedValue = newValue;
//     });
//   },
//   items: items
//       .map<DropdownMenuItem<String>>((String value) {
//     return DropdownMenuItem<String>(
//       value: value,
//       child: Text(
//         value,
//       ),
//     );
//   }).toList(),
// ),
                    DropdownButtonHideUnderline(
                  child: DropdownButton(
                    enableFeedback: true,
                      isExpanded: true,
                      //underline: const SizedBox(),
                      value: selectedValue,
                      icon: Icon(Icons.arrow_drop_down,
                          color: Color(0xffD4D4D4)),
                      style: TextStyle(
                          color: Color(0xff00DC00),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          fontSize: mHeight * 0.06 / 3,
                          overflow: TextOverflow.ellipsis),
                      items: exitItems
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                enabled: BelnetLib.isConnected ? false : true,
                                child: Center(
                                  child: Text(
                                    item,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff00DC00),
                                        fontFamily: 'Poppins'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value;
                          print('$selectedValue');
                        });
                      }),
                )),
          ),
        ),
        // Padding(
        //   padding: EdgeInsets.only(left: 45, right: 45 , top: 20),
        //   child: TextFormField(
        //     validator: (value) {
        //       final trimmed = value.trim();
        //       if (trimmed == "") return null;
        //       if (trimmed == ".beldex" || !trimmed.endsWith(".beldex"))
        //         return "Invalid exit node value";
        //       return null;
        //     },
        //     controller: exitInput,
        //     cursorColor: color,
        //     style: TextStyle(color: color),
        //     decoration: InputDecoration(
        //         filled: true,
        //         fillColor: appModel.darkTheme
        //             ? Color.fromARGB(255, 35, 35, 35)
        //             : Color.fromARGB(255, 226, 226, 226),
        //         border: InputBorder.none,
        //         labelStyle: TextStyle(color: color),
        //         labelText: 'Exit Node'),
        //   ),
        // ),
        // Padding(
        //   padding: EdgeInsets.all(8.0),
        //   child: Text(
        //     BelnetLib.isConnected ? "Connected" : "Not Connected",
        //     style: TextStyle(
        //         color: color,
        //         fontSize: MediaQuery.of(context).size.height * 0.024),
        //   ),
        // ),
        // TextButton(
        //     onPressed: () async {
        //       val= (await BelnetLib.status).toString();
        //       print(
        //           'Test is the status${(await BelnetLib.status).toString()}');
        //     },
        //     child: Text("$val"))
      ],
    );
  }
}


