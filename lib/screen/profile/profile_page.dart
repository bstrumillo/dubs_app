import 'package:dubs_app/DesignSystem/colors.dart';
import 'package:dubs_app/DesignSystem/dimensions.dart';
import 'package:dubs_app/DesignSystem/texts.dart';
import 'package:dubs_app/Widgets/WaveWidget.dart';
import 'package:dubs_app/bloc/profile/profile_bloc.dart';
import 'package:dubs_app/bloc/profile/profile_events.dart';
import 'package:dubs_app/bloc/profile/profile_states.dart';
import 'package:dubs_app/logger/log_printer.dart';
import 'package:dubs_app/model/user.dart';
import 'package:dubs_app/repository/user_repository.dart';
import 'package:dubs_app/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class ProfilePageInput {
  User user;
  UserRepository userRepo;

  ProfilePageInput(this.user, this.userRepo);
}

class ProfilePage extends StatefulWidget {
  ProfilePageInput input;

  ProfilePage({PageStorageKey key, @required this.input}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileBloc _bloc;

  Logger _logger = getLogger("ProfilePage");

  User get _currentUser => widget.input.user;

  UserRepository get _userRepo => widget.input.userRepo;

  @override
  void initState() {
    _bloc = ProfileBloc(userRepo: _userRepo, user: _currentUser);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onLogoutPressed() {
    _bloc.add(ProfileLogoutEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _bloc,
      listener: (
        BuildContext context,
        ProfileState state,
      ) {
        if (state is ProfileLoggedOutState) {
          _logger.v("listener- logging out");
          Navigator.of(context).pushNamed(loginRoute);
        }
      },
      child: BlocBuilder(
          bloc: _bloc,
          builder: (
            BuildContext context,
            ProfileState state,
          ) {
            final size = MediaQuery.of(context).size;
            return Scaffold(
                backgroundColor: DarwinRed,
                body: Stack(children: [
                  WaveWidget(
                    size: size,
                    yOffset: size.height / 1.25,
                    color: const Color(0xfff2f2f2),
                  ),
                  Column(
                    children: <Widget>[
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
                                "Profile",
                                style: primaryH1Bold,
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            padding: spacer.top.xs + spacer.bottom.xs,
                            margin: spacer.right.md,
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Logout', style: darkprimaryPBold),
                              color: Colors.white,
                              onPressed: _onLogoutPressed,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  )
                ]));
          }),
    );
  }
}
