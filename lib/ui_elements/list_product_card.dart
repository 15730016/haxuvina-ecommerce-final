import 'package:haxuvina/custom/box_decorations.dart';
import 'package:haxuvina/helpers/system_config.dart';
import 'package:haxuvina/my_theme.dart';
import 'package:haxuvina/screens/product/product_details.dart';
import 'package:flutter/material.dart';

class ListProductCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;

  ListProductCard(
      {Key? key,
      this.id,
      required this.slug,
      this.image,
      this.name,
      this.main_price,
      this.stroked_price,
      this.has_discount})
      : super(key: key);

  @override
  _ListProductCardState createState() => _ListProductCardState();
}

class _ListProductCardState extends State<ListProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            slug: widget.slug,
          );
        }));
      },
      child: Container(
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Container(
              width: 100,
              height: 100,
              child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(6), right: Radius.zero),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: widget.image!,
                    fit: BoxFit.cover,
                  ))),
          Flexible(
            child: Container(
              padding:
                  EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 14),
              //width: 240,
              height: 100,
              //color: Colors.red,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    //color:Colors.blue,
                    child: Text(
                      widget.name!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  Container(
                    //color:Colors.green,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          SystemConfig.systemCurrency!.code != null
                              ? widget.main_price!.replaceAll(
                                  SystemConfig.systemCurrency!.code!,
                                  SystemConfig.systemCurrency!.symbol!)
                              : widget.main_price!,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          style: TextStyle(
                              color: MyTheme.accent_color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        widget.has_discount!
                            ? Text(
                                SystemConfig.systemCurrency!.code != null
                                    ? widget.stroked_price!.replaceAll(
                                        SystemConfig.systemCurrency!.code!,
                                        SystemConfig.systemCurrency!.symbol!)
                                    : widget.stroked_price!,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: MyTheme.medium_grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400),
                              )
                            : Container(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
