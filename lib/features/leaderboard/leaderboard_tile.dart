import 'package:flutter/material.dart';

class LeaderboardTile extends StatelessWidget{

  final player;

  final int index;

  LeaderboardTile({

    required this.player,

    required this.index

  });

  @override

  Widget build(BuildContext context){

    Color medalColor = Colors.white;

    if(index == 0){

      medalColor = Colors.amber;

    }

    if(index == 1){

      medalColor = Colors.grey;

    }

    if(index == 2){

      medalColor = Colors.brown;

    }

    return Container(

        margin:
        EdgeInsets.symmetric(
            horizontal:10,
            vertical:6),

        padding: EdgeInsets.all(15),

        decoration: BoxDecoration(

            gradient: LinearGradient(

                colors:[
                  Color(0xff1e293b),
                  Color(0xff020617)
                ]),

            borderRadius:
            BorderRadius.circular(20),

            boxShadow:[

              BoxShadow(
                  color: Colors.black,
                  blurRadius:10)

            ]

        ),

        child: Row(

            children:[

              Text(

                  "#${index+1}",

                  style: TextStyle(

                      color: medalColor,

                      fontSize:20,

                      fontWeight:
                      FontWeight.bold)

              ),

              SizedBox(width:20),

              CircleAvatar(

                  backgroundColor:
                  Colors.blue,

                  child:
                  Text(player['displayName'][0])

              ),

              SizedBox(width:15),

              Text(

                  player['displayName'],

                  style: TextStyle(

                      color: Colors.white,

                      fontSize:18)

              ),

              Spacer(),

              Column(

                  children:[

                    Text(

                        player['rating'].toString(),

                        style: TextStyle(

                            color: Colors.green,

                            fontSize:20,

                            fontWeight:
                            FontWeight.bold)

                    ),

                    Text(

                        "rating",

                        style:
                        TextStyle(
                            color: Colors.grey))

                  ]

              )

            ]

        )

    );

  }

}