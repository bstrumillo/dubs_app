import 'package:dubs_app/DesignSystem/colors.dart';
import 'package:dubs_app/Widgets/WaveWidget.dart';
import 'package:dubs_app/model/user.dart';
import 'package:dubs_app/model/user_search_result.dart';
import 'package:dubs_app/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dubs_app/DesignSystem/texts.dart';
import 'package:dubs_app/DesignSystem/dimensions.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// input arguments to the home page
class HomePageInput {
  User user;

  HomePageInput(this.user) : assert(user != null);
}

class HomePage extends StatefulWidget {
  HomePageInput input;

  HomePage({PageStorageKey key, @required this.input})
      : assert(input != null),
        super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

PanelController _spc = PanelController();

Widget buildCloseButton(BuildContext context) {
  return IconButton(
    alignment: Alignment.topLeft,
    icon: Icon(Icons.close),
    color: Colors.black,
    iconSize: 28,
    onPressed: () => _spc.close(),
  );
}

class _HomePageState extends State<HomePage> {
  User get _currentUser => widget.input.user;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: <Widget>[
        Scaffold(
          backgroundColor: DarwinRed,
          body: Stack(children: [
            WaveWidget(
              size: size,
              yOffset: size.height / 5.5,
              color: const Color(0xfff2f2f2),
            ),
            SlidingUpPanel(
              controller: _spc,
              backdropEnabled: true,
              backdropColor: DarwinWhite,
              backdropOpacity: .8,
              backdropTapClosesPanel: true,
              color: Colors.white,
              minHeight: 0,
              maxHeight: 225,
              defaultPanelState: PanelState.CLOSED,
              padding: (spacer.left.none + spacer.top.xs),
              panel: Stack(
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    padding: spacer.top.xs,
                    margin: spacer.left.sm + spacer.bottom.xs,
                    child: Text(
                      'Invite friends',
                      style: darkprimaryPBold,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    padding: spacer.top.xxl,
                    margin: spacer.bottom.xs,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ClipOval(
                          child: Material(
                            color: Colors.blue, // button color
                            child: InkWell(
                              splashColor: Colors.grey[200], // inkwell color
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.email,
                                    semanticLabel: 'email',
                                    size: 30.0,
                                    color: DarwinWhite),
                              ),
                              onTap: () {},
                            ),
                          ),
                        ),
                        ClipOval(
                          child: Material(
                            color: Colors.green[500], // button color
                            child: InkWell(
                              splashColor: Colors.grey[200], // inkwell color
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.message,
                                    semanticLabel: 'messages',
                                    size: 30.0,
                                    color: DarwinWhite),
                              ),
                              onTap: () {},
                            ),
                          ),
                        ),
                        ClipOval(
                          child: Material(
                            color: Colors.red[500], // button color
                            child: InkWell(
                              splashColor: Colors.grey[200], // inkwell color
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.content_copy,
                                    semanticLabel: 'copy link',
                                    size: 30.0,
                                    color: DarwinWhite),
                              ),
                              onTap: () {},
                            ),
                          ),
                        ),
                        ClipOval(
                          child: Material(
                            color: Colors.grey, // button color
                            child: InkWell(
                              splashColor: Colors.grey[200], // inkwell color
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: Icon(Icons.more_horiz,
                                    semanticLabel: 'more options',
                                    size: 30.0,
                                    color: DarwinWhite),
                              ),
                              onTap: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    padding: spacer.top.xs + spacer.bottom.lg,
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Cancel', style: redprimaryPBold),
                      color: Colors.white,
                      onPressed: () => _spc.close(),
                    ),
                  )
                ],
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        padding: spacer.top.xxl,
                        margin: spacer.left.xs + spacer.right.xs,
                        child: Stack(children: [
                          Container(
                            padding: spacer.left.xs +
                                spacer.top.xs +
                                spacer.bottom.xs,
                            child: Container(
                              alignment: Alignment.topLeft,
                              padding: spacer.top.xxs,
                              margin: spacer.left.none,
                              child: Text(
                                "Home",
                                style: primaryH1Bold,
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            padding: spacer.top.xs + spacer.bottom.xs,
                            margin: spacer.right.md,
                            child: ClipOval(
                              child: Material(
                                borderOnForeground: true,
                                color: Colors.white,
                                child: InkWell(
                                  child: Container(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.edit,
                                        color: DarwinRed,
                                      )),
                                  onTap: () {},
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      // Modal containing 'add friends' form
                      Container(
                        height: MediaQuery.of(context).size.height,
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          padding: spacer.all.none,
                          children: [
                            Container(
                              height: 175.0,
                              margin:
                                  EdgeInsets.only(top: 40, left: 12, right: 12),
                              child: Stack(children: [
                                Container(
                                  padding: spacer.left.md +
                                      spacer.top.xs +
                                      spacer.bottom.xs,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    color: const Color(0xffffffff),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0x1a000000),
                                          offset: Offset(5, 5),
                                          blurRadius: 15)
                                    ],
                                  ),
                                  child: Column(children: [
                                    Container(
                                      alignment: Alignment.topLeft,
                                      padding: spacer.top.xxs,
                                      margin: spacer.left.none,
                                      child: Text(
                                        "Welcome, ${_currentUser.username}",
                                        style: darkprimaryH1Bold,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.topLeft,
                                      padding: spacer.top.xxs,
                                      margin:
                                          spacer.left.none + spacer.right.xxs,
                                      child: Text(
                                        "Let’s get started by adding some of your friends.",
                                        style: darkprimaryPBold,
                                      ),
                                    ),
                                  ]),
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  padding: spacer.bottom.xs +
                                      spacer.top.xs +
                                      spacer.right.md,
                                  child: RaisedButton(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Add Friends',
                                        style: primaryPBold),
                                    color: DarwinRed,
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                          addFriendsRoute,
                                          arguments: _currentUser);
                                    },
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.bottomLeft,
                                  padding: spacer.bottom.xs +
                                      spacer.top.xs +
                                      spacer.left.sm,
                                  child: RaisedButton(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(width: 0.5),
                                    ),
                                    child: Text('Invite Friends',
                                        style: darkprimaryPBold),
                                    color: Colors.white,
                                    onPressed: () => _spc.open(),
                                  ),
                                ),
                              ]),
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              padding: spacer.top.xs,
                              margin: spacer.left.xs + spacer.right.xs,
                              child: Stack(children: [
                                Container(
                                  padding: spacer.left.xs +
                                      spacer.top.xs +
                                      spacer.bottom.xs,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    padding: spacer.top.xxs,
                                    margin: spacer.left.none,
                                    child: Text(
                                      "Added me",
                                      style: darkPrimaryH1Bold,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              margin: spacer.left.xs +
                                  spacer.right.xs +
                                  spacer.bottom.xxs,
                              child: ListTile(
                                title:
                                    Text('Gmilli20', style: darkprimaryPBold),
                                trailing: Container(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 0,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          FlatButton(
                                            padding: spacer.all.none +
                                                spacer.right.xs,
                                            color: Colors.grey[100],
                                            splashColor: Colors.greenAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                            ),
                                            onPressed: () {},
                                            child: Wrap(
                                              // alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: <Widget>[
                                                IconButton(
                                                  alignment: Alignment.center,
                                                  icon: Icon(
                                                    Icons.person_add,
                                                    color: Colors.black,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Accept Request',
                                                  enableFeedback: true,
                                                  color: Colors.grey[300],
                                                  onPressed: () {},
                                                ),
                                                Text(
                                                  'Accept',
                                                  // textAlign: TextAlign.center,
                                                  style: darkprimaryPBoldSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        tooltip: 'Decline',
                                        enableFeedback: true,
                                        color: Colors.grey[300],
                                        onPressed: () {},
                                      )
                                    ],
                                  ),
                                ),
                                contentPadding: spacer.top.xxs +
                                    spacer.bottom.xxs +
                                    spacer.left.xs +
                                    spacer.right.xxs,
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              margin: spacer.left.xs + spacer.right.xs,
                              child: ListTile(
                                title: Text('SpookyCactus',
                                    style: darkprimaryPBold),
                                trailing: Container(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 0,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          FlatButton(
                                            padding: spacer.all.none +
                                                spacer.right.xs,
                                            color: Colors.grey[100],
                                            splashColor: Colors.greenAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100.0),
                                            ),
                                            onPressed: () {},
                                            child: Wrap(
                                              // alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: <Widget>[
                                                IconButton(
                                                  alignment: Alignment.center,
                                                  icon: Icon(
                                                    Icons.person_add,
                                                    color: Colors.black,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Accept Request',
                                                  enableFeedback: true,
                                                  color: Colors.grey[300],
                                                  onPressed: () {},
                                                ),
                                                Text(
                                                  'Accept',
                                                  // textAlign: TextAlign.center,
                                                  style: darkprimaryPBoldSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        tooltip: 'Decline',
                                        enableFeedback: true,
                                        color: Colors.grey[300],
                                        onPressed: () {},
                                      )
                                    ],
                                  ),
                                ),
                                contentPadding: spacer.top.xxs +
                                    spacer.bottom.xxs +
                                    spacer.left.xs +
                                    spacer.right.xxs,
                              ),
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              padding: spacer.top.xs,
                              margin: spacer.left.xs + spacer.right.xs,
                              child: Stack(children: [
                                Container(
                                  padding: spacer.left.xs +
                                      spacer.top.xs +
                                      spacer.bottom.xs,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    padding: spacer.top.xxs,
                                    margin: spacer.left.none,
                                    child: Text(
                                      "Friends",
                                      style: darkPrimaryH1Bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  padding: spacer.top.xs + spacer.bottom.xs,
                                  margin: spacer.right.md,
                                  child: Container(
                                    width: 45,
                                    child: FlatButton(
                                      padding:
                                          spacer.all.none + spacer.right.none,
                                      color: Colors.white,
                                      splashColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                      ),
                                      onPressed: () {},
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            'Edit',
                                            // textAlign: TextAlign.center,
                                            style: darkprimaryPBoldSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              margin: spacer.left.xs +
                                  spacer.right.xs +
                                  spacer.bottom.xxs,
                              child: ListTile(
                                title:
                                    Text('Gmilli20', style: darkprimaryPBold),
                                trailing: FlatButton(
                                  padding: spacer.all.none + spacer.right.xs,
                                  color: Colors.grey[100],
                                  splashColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  onPressed: () {},
                                  child: Wrap(
                                    // alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      IconButton(
                                        alignment: Alignment.center,
                                        icon: Icon(
                                          Icons.people,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        tooltip: 'Friends',
                                        enableFeedback: true,
                                        color: Colors.grey[300],
                                        onPressed: () {},
                                      ),
                                      Text(
                                        'Friends',
                                        // textAlign: TextAlign.center,
                                        style: darkprimaryPBoldSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                contentPadding: spacer.top.xxs +
                                    spacer.bottom.xxs +
                                    spacer.left.xs +
                                    spacer.right.xxs,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
