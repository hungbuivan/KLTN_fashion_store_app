import 'package:fashion_store_app/core/theme/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchArea extends StatelessWidget {
  const SearchArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none
                    ),
                    hintText: "Search"    ,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              )
          ),
          SizedBox(width: 10,),
          InkWell(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                  "${imagePath}filter-edit-svgrepo-com.svg"),
            ),
          )
        ],
      ),
    );
  }
}
