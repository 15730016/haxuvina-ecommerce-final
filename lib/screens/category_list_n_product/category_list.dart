import 'package:haxuvina/custom/btn.dart';
import 'package:haxuvina/custom/device_info.dart';
import 'package:haxuvina/custom/useful_elements.dart';
import 'package:haxuvina/data_model/category_response.dart';
import 'package:haxuvina/helpers/shared_value_helper.dart';
import 'package:haxuvina/helpers/shimmer_helper.dart';
import 'package:haxuvina/my_theme.dart';
import 'package:haxuvina/presenter/bottom_appbar_index.dart';
import 'package:haxuvina/repositories/category_repository.dart';
import 'package:haxuvina/screens/category_list_n_product/category_products.dart';
import 'package:flutter/material.dart';
import 'package:haxuvina/gen_l10n/app_localizations.dart';

import '../../custom/category_item_card_widget.dart';

class CategoryList extends StatefulWidget {
  CategoryList({
    Key? key,
    required this.slug,
    this.is_base_category = false,
    this.is_top_category = false,
    this.bottomAppbarIndex,
  }) : super(key: key);

  final String slug;
  final bool is_base_category;
  final bool is_top_category;
  final BottomAppbarIndex? bottomAppbarIndex;

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // ✅ Cố định LTR cho tiếng Việt
      child: Stack(children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            child: buildAppBar(context),
            preferredSize: Size(
              DeviceInfo(context).width!,
              50,
            ),
          ),
          body: buildBody(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: widget.is_base_category || widget.is_top_category
              ? Container(
                  height: 0,
                )
              : buildBottomContainer(),
        )
      ]),
    );
  }

  Widget buildBody() {
    return Container(
      color: Color(0xffECF1F5),
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                buildCategoryList(),
                Container(
                  height: widget.is_base_category ? 60 : 90,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      leading: widget.is_base_category
          ? Builder(
              builder: (context) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                child: UsefulElements.backToMain(context, go_back: false, color: "black"),
              ),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.arrow_back, color: MyTheme.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      title: Text(
        getAppBarTitle(),
        style: TextStyle(
            fontSize: 16,
            color: Color(0xff121423),
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  String getAppBarTitle() {
    String name = widget.is_top_category
        ? AppLocalizations.of(context)!.top_categories_ucf
        : AppLocalizations.of(context)!.categories_ucf;

    return name;
  }

  buildCategoryList() {
    var data = widget.is_top_category
        ? CategoryRepository().getTopCategories()
        : CategoryRepository().getCategories(parent_id: widget.slug);
    return FutureBuilder(
      future: data,
      builder: (context, AsyncSnapshot<CategoryResponse> snapshot) {
        // if getting response is
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            child: ShimmerHelper().buildCategoryCardShimmer(
                is_base_category: widget.is_base_category),
          );
        }
        // if response has issue
        if (snapshot.hasError) {
          return Container(
            height: 10,
          );
        } else if (snapshot.hasData) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.7,
              crossAxisCount: 3,
            ),
            itemCount: snapshot.data!.categories!.length,
            padding: EdgeInsets.only(
                left: 18, right: 18, bottom: widget.is_base_category ? 30 : 0),
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return CategoryItemCardWidget(
                  categoryResponse: snapshot.data!, index: index);
            },
          );
        } else {
          return SingleChildScrollView(
            child: ShimmerHelper().buildCategoryCardShimmer(
              is_base_category: widget.is_base_category,
            ),
          );
        }
      },
    );
  }

  Container buildBottomContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      height: widget.is_base_category ? 0 : 80,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                width: (MediaQuery.of(context).size.width - 32),
                height: 40,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8.0))),
                  child: Text(
                    AppLocalizations.of(context)!.all_products_of_ucf + " ",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return CategoryProducts(
                            slug: widget.slug,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
