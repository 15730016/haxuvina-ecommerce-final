import 'package:flutter/material.dart';
import 'package:haxuvina/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../custom/lang_text.dart';
import '../helpers/shared_value_helper.dart';
import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../repositories/product_repository.dart';
import '../ui_elements/product_card.dart';

class InHouseProducts extends StatefulWidget {
  const InHouseProducts({Key? key}) : super(key: key);

  @override
  State<InHouseProducts> createState() => _InHouseProductsState();
}

class _InHouseProductsState extends State<InHouseProducts> {
  ScrollController _scrollController = ScrollController();

  List<dynamic> _inHouseProductList = [];
  bool _isFetch = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  fetchData() async {
    var productResponse =
        await ProductRepository().getInHouseProducts(page: _page);
    _inHouseProductList.addAll(productResponse.products);
    _isFetch = false;
    _totalData = productResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _inHouseProductList.clear();
    _isFetch = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  late VoidCallback _scrollListener;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    fetchData();

    _scrollListener = () {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    };

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.ltr, // ✅ Cố định LTR cho tiếng Việt
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            buildInHouserProductList(context),
            Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer())
          ],
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalData == _inHouseProductList.length
            ? AppLocalizations.of(context)!.no_more_products_ucf
            : AppLocalizations.of(context)!.loading_more_products_ucf),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      // centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        LangText(context).local.in_house_products_ucf,
        style: TextStyle(
            fontSize: 16,
            color: MyTheme.dark_font_grey,
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildInHouserProductList(context) {
    if (_isFetch && _inHouseProductList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_inHouseProductList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            itemCount: _inHouseProductList.length,
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: 20.0, bottom: 10, left: 18, right: 18),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ProductCard(
                id: _inHouseProductList[index].id,
                slug: _inHouseProductList[index].slug,
                image: _inHouseProductList[index].thumbnail_image,
                name: _inHouseProductList[index].name,
                main_price: _inHouseProductList[index].main_price,
                stroked_price: _inHouseProductList[index].stroked_price,
                has_discount: _inHouseProductList[index].has_discount,
                discount: _inHouseProductList[index].discount,
                is_wholesale: _inHouseProductList[index].is_wholesale ?? false,
              );
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_data_is_available));
    } else {
      return Container(); // should never be happening
    }
  }
}
