import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/pages/dashboard.dart';
import 'package:notesapp/pages/profile.dart';
import 'package:notesapp/pages/schedule.dart';
import 'package:notesapp/pages/tasks.dart';

class MyNavBar extends StatelessWidget {
  MyNavBar({Key? key, required this.currentIndex, required this.email})
      : super(key: key);

  final int currentIndex;
  final String email;
  final primaryColor = const Color(0xff4338CA);
  final secondaryColor = const Color(0xff6D28D9);
  final accentColor = const Color(0xffffffff);
  final backgroundColor = const Color(0xffffffff);
  final errorColor = const Color(0xffEF4444);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: SizedBox(
        height: 56,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBottomBar(
                text: "Home",
                icon: CupertinoIcons.house_fill,
                selected: currentIndex == 0,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Dashboard(
                        email: email,
                      ), // required
                    ),
                  );
                },
              ),
              IconBottomBar(
                text: "Schedule",
                icon: CupertinoIcons.calendar,
                selected: currentIndex == 1,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SchedulePage(
                              email: email,
                            )),
                  );
                },
              ),
              IconBottomBar(
                text: "Tasks",
                icon: CupertinoIcons.square_list_fill,
                selected: currentIndex == 2,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TasksPage(
                              email: email,
                            )),
                  );
                },
              ),
              IconBottomBar(
                text: "Profile",
                icon: CupertinoIcons.person_fill,
                selected: currentIndex == 3,
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfilePage(email: email)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  const IconBottomBar({
    Key? key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final IconData icon;
  final bool selected;
  final Function() onPressed;

  final primaryColor = const Color(0xff050C20);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: selected ? 30 : 25, // 👈 Profile icon gets bigger
            color: selected ? primaryColor : Colors.black54,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: .1,
            color: selected ? primaryColor : Colors.grey.withOpacity(.75),
          ),
        ),
      ],
    );
  }
}
