import 'package:flutter/material.dart';
import 'package:haxuvina/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:one_context/one_context.dart';

import '../../../custom/btn.dart';
import '../../../custom/toast_component.dart';
import '../../../custom/useful_elements.dart';
import '../../../helpers/reg_ex_inpur_formatter.dart';
import '../../../helpers/shared_value_helper.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../my_theme.dart';
import '../../../repositories/brand_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/search_repository.dart';
import '../../../ui_elements/brand_square_card.dart';
import '../../../ui_elements/product_card.dart';
import '../../../ui_elements/shop_square_card.dart';

class WhichFilter {
  String option_key;
  String name;

  WhichFilter(this.option_key, this.name);

  static List<WhichFilter> getWhichFilterList() {
    return <WhichFilter>[
      WhichFilter(
          'product', AppLocalizations.of(OneContext().context!)!.product_ucf),
      WhichFilter(
          'sellers', AppLocalizations.of(OneContext().context!)!.sellers_ucf),
      WhichFilter(
          'brands', AppLocalizations.of(OneContext().context!)!.brands_ucf),
    ];
  }
}

class SearchWidget extends StatefulWidget {
  SearchWidget({
    Key? key,
    this.selected_filter = "product",
  }) : super(key: key);

  final String selected_filter;

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _amountValidator = RegExInputFormatter.withRegex(
      '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$');

  ScrollController _productScrollController = ScrollController();
  ScrollController _brandScrollController = ScrollController();
  ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  WhichFilter? _selectedFilter;
  String? _givenSelectedFilterOptionKey; // may be it can come from another page
  String? _selectedSort = "";

  List<WhichFilter> _which_filter_list = WhichFilter.getWhichFilterList();
  List<DropdownMenuItem<WhichFilter>>? _dropdownWhichFilterItems;
  List<dynamic> _selectedCategories = [];
  List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = new TextEditingController();
  final TextEditingController _minPriceController = new TextEditingController();
  final TextEditingController _maxPriceController = new TextEditingController();

  //--------------------
  List<dynamic> _filterBrandList = [];
  bool _filteredBrandsCalled = false;
  List<dynamic> _filterCategoryList = [];
  bool _filteredCategoriesCalled = false;

  List<dynamic> _searchSuggestionList = [];

  //----------------------------------------
  String? _searchKey = "";

  List<dynamic> _productList = [];
  bool _isProductInitial = true;
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;

  List<dynamic> _brandList = [];
  bool _isBrandInitial = true;
  int _brandPage = 1;
  int? _totalBrandData = 0;
  bool _showBrandLoadingContainer = false;

  List<dynamic> _shopList = [];
  bool _isShopInitial = true;
  int _shopPage = 1;
  int? _totalShopData = 0;
  bool _showShopLoadingContainer = false;

  //----------------------------------------

  fetchFilteredBrands() async {
    var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
    _filterBrandList.addAll(filteredBrandResponse.brands!);
    _filteredBrandsCalled = true;
    setState(() {});
  }

  fetchFilteredCategories() async {
    var filteredCategoriesResponse =
        await CategoryRepository().getFilterPageCategories();
    _filterCategoryList.addAll(filteredCategoriesResponse.categories!);
    _filteredCategoriesCalled = true;
    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _productScrollController.dispose();
    _brandScrollController.dispose();
    _shopScrollController.dispose();
    super.dispose();
  }

  init() {
    _givenSelectedFilterOptionKey = widget.selected_filter;

    _dropdownWhichFilterItems =
        buildDropdownWhichFilterItems(_which_filter_list);
    _selectedFilter = _dropdownWhichFilterItems![0].value;

    for (int x = 0; x < _dropdownWhichFilterItems!.length; x++) {
      if (_dropdownWhichFilterItems![x].value!.option_key ==
          _givenSelectedFilterOptionKey) {
        _selectedFilter = _dropdownWhichFilterItems![x].value;
      }
    }

    fetchFilteredCategories();
    fetchFilteredBrands();

    if (_selectedFilter!.option_key == "brands") {
      fetchBrandData();
    } else {
      fetchProductData();
    }

    //set scroll listeners

    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        fetchProductData();
      }
    });

    _brandScrollController.addListener(() {
      if (_brandScrollController.position.pixels ==
          _brandScrollController.position.maxScrollExtent) {
        setState(() {
          _brandPage++;
        });
        _showBrandLoadingContainer = true;
        fetchBrandData();
      }
    });
  }

  fetchProductData() async {
    var productResponse = await ProductRepository().getFilteredProducts(
        page: _productPage,
        name: _searchKey,
        sort_key: _selectedSort,
        brands: _selectedBrands.join(",").toString(),
        categories: _selectedCategories.join(",").toString(),
        max: _maxPriceController.text.toString(),
        min: _minPriceController.text.toString());

    _productList.addAll(productResponse.products!);
    _isProductInitial = false;
    _totalProductData = productResponse.meta!.total;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  resetProductList() {
    _productList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  fetchBrandData() async {
    var brandResponse =
        await BrandRepository().getBrands(page: _brandPage, name: _searchKey);
    _brandList.addAll(brandResponse.brands!);
    _isBrandInitial = false;
    _totalBrandData = brandResponse.meta!.total;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  resetBrandList() {
    _brandList.clear();
    _isBrandInitial = true;
    _totalBrandData = 0;
    _brandPage = 1;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _searchSuggestionList.clear();
    setState(() {});
  }

  resetShopList() {
    _shopList.clear();
    _isShopInitial = true;
    _totalShopData = 0;
    _shopPage = 1;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onProductListRefresh() async {
    reset();
    resetProductList();
    fetchProductData();
  }

  Future<void> _onBrandListRefresh() async {
    reset();
    resetBrandList();
    fetchBrandData();
  }

  _applyProductFilter() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onSearchSubmit() {
    reset();
    if (_selectedFilter!.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  _onSortChange() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onWhichFilterChange() {
    if (_selectedFilter!.option_key == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
      List which_filter_list) {
    List<DropdownMenuItem<WhichFilter>> items = [];
    for (WhichFilter which_filter_item
        in which_filter_list as Iterable<WhichFilter>) {
      items.add(
        DropdownMenuItem(
          value: which_filter_item,
          child: Text(which_filter_item.name),
        ),
      );
    }
    return items;
  }

  Container buildProductLoadingContainer() {
    return Container(
      height: _showProductLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalProductData == _productList.length
            ? AppLocalizations.of(context)!.no_more_products_ucf
            : AppLocalizations.of(context)!.loading_more_products_ucf),
      ),
    );
  }

  Container buildBrandLoadingContainer() {
    return Container(
      height: _showBrandLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalBrandData == _brandList.length
            ? AppLocalizations.of(context)!.no_more_brands_ucf
            : AppLocalizations.of(context)!.loading_more_brands_ucf),
      ),
    );
  }

  Container buildShopLoadingContainer() {
    return Container(
      height: _showShopLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalShopData == _shopList.length
            ? AppLocalizations.of(context)!.no_more_shops_ucf
            : AppLocalizations.of(context)!.loading_more_shops_ucf),
      ),
    );
  }

  //--------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.ltr, // ✅ Cố định LTR cho tiếng Việt
      child: Scaffold(
        endDrawer: buildFilterDrawer(),
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        body: Stack(fit: StackFit.loose, children: [
          _selectedFilter!.option_key == 'product'
              ? buildProductList()
              : (_selectedFilter!.option_key == 'brands'
                  ? buildBrandList()
                  : buildShopList()),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: buildAppBar(context),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: _selectedFilter!.option_key == 'product'
                  ? buildProductLoadingContainer()
                  : (_selectedFilter!.option_key == 'brands'
                      ? buildBrandLoadingContainer()
                      : buildShopLoadingContainer()))
        ]),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
        backgroundColor: MyTheme.white.withOpacity(0.95),
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        actions: [
          new Container(),
        ],
        centerTitle: false,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
          child: Column(
            children: [buildTopAppbar(context), buildBottomAppBar(context)],
          ),
        ));
  }

  Row buildBottomAppBar(BuildContext context) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            // border: Border.symmetric(
            //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
            //     horizontal: BorderSide(color: MyTheme.light_grey, width: 1))
          ),
          padding: EdgeInsets.fromLTRB(16, 5, 8, 5),
          height: 36,
          width: MediaQuery.of(context).size.width * .33,
          child: new DropdownButton<WhichFilter>(
            dropdownColor: Colors.white,
            isExpanded: true,
            icon: Padding(
              padding: app_language_rtl.$!
                  ? const EdgeInsets.only(right: 18.0)
                  : const EdgeInsets.only(left: 18.0),
              child: Icon(Icons.expand_more, color: Colors.black54),
            ),
            hint: Text(
              AppLocalizations.of(context)!.products_ucf,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
              ),
            ),
            style: TextStyle(color: Colors.black, fontSize: 13),
            iconSize: 13,
            underline: SizedBox(),
            value: _selectedFilter,
            items: _dropdownWhichFilterItems,
            onChanged: (WhichFilter? selectedFilter) {
              setState(() {
                _selectedFilter = selectedFilter;
              });

              _onWhichFilterChange();
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilter!.option_key == "product"
                ? _scaffoldKey.currentState!.openEndDrawer()
                : ToastComponent.showDialog(
                    AppLocalizations.of(context)!
                        .you_can_use_sorting_while_searching_for_products,
                  );
            ;
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // border: Border.symmetric(
              //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
              //     horizontal:
              //         BorderSide(color: MyTheme.light_grey, width: 1))
            ),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
                child: Container(
              width: 50,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 13,
                  ),
                  SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context)!.filter_ucf,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilter!.option_key == "product"
                ? showDialog(
                    context: context,
                    builder: (_) => Directionality(
                          textDirection: app_language_rtl.$!
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: AlertDialog(
                            backgroundColor: Colors.white,
                            contentPadding: EdgeInsets.only(
                                top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
                            content: StatefulBuilder(builder:
                                (BuildContext context, StateSetter setState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .sort_products_by_ucf,
                                      )),
                                  RadioListTile(
                                    dense: true,
                                    value: "",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .default_ucf),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    dense: true,
                                    value: "price_high_to_low",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .price_high_to_low),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    dense: true,
                                    value: "price_low_to_high",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .price_low_to_high),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    dense: true,
                                    value: "new_arrival",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .new_arrival_ucf),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    dense: true,
                                    value: "popularity",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .popularity_ucf),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  RadioListTile(
                                    dense: true,
                                    value: "top_rated",
                                    groupValue: _selectedSort,
                                    activeColor: MyTheme.font_grey,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(AppLocalizations.of(context)!
                                        .top_rated_ucf),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        _selectedSort = value;
                                      });
                                      _onSortChange();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            }),
                            actions: [
                              Btn.basic(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .close_all_capital,
                                  style: TextStyle(color: MyTheme.medium_grey),
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                },
                              ),
                            ],
                          ),
                        ))
                : ToastComponent.showDialog(
                    AppLocalizations.of(context)!
                        .you_can_use_filters_while_searching_for_products,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // border: Border.symmetric(
              //     vertical: BorderSide(color: MyTheme.light_grey, width: .5),
              //     horizontal:
              //         BorderSide(color: MyTheme.light_grey, width: 1))
            ),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
                child: Container(
              width: 50,
              child: Row(
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 13,
                  ),
                  SizedBox(width: 2),
                  Text(
                    AppLocalizations.of(context)!.sort_ucf,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ),
        )
      ],
    );
  }

  Row buildTopAppbar(BuildContext context) {
    return Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            padding: EdgeInsets.zero,
            icon: UsefulElements.backButton(context),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * .84,
            child: Container(
              height: 58,
              //color: Colors.amber,
              child: Padding(
                  padding: MediaQuery.of(context).viewPadding.top >
                          30 //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                      ? const EdgeInsets.fromLTRB(0, 14, 0, 10)
                      : const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 0.0),
                  child: TypeAheadField(
                    suggestionsCallback: (pattern) async {
                      //return await BackendService.getSuggestions(pattern);
                      var suggestions = await SearchRepository()
                          .getSearchSuggestionListResponse(
                              query_key: pattern,
                              type: _selectedFilter!.option_key);
                      //print(suggestions.toString());
                      return suggestions;
                    },
                    loadingBuilder: (context) {
                      return Container(
                        height: 50,
                        color: Colors.white,
                        child: Center(
                            child: Text(
                                AppLocalizations.of(context)!
                                    .loading_suggestions,
                                style: TextStyle(color: MyTheme.medium_grey))),
                      );
                    },
                    itemBuilder: (context, dynamic suggestion) {
                      //print(suggestion.toString());
                      var subtitle =
                          "${AppLocalizations.of(context)!.searched_for_all_lower} ${suggestion.count} ${AppLocalizations.of(context)!.times_all_lower}";
                      if (suggestion.type != "search") {
                        subtitle =
                            "${suggestion.type_string} ${AppLocalizations.of(context)!.found_all_lower}";
                      }
                      return ListTile(
                        tileColor: Colors.white,
                        dense: true,
                        title: Text(
                          suggestion.query,
                          style: TextStyle(
                              color: suggestion.type != "search"
                                  ? MyTheme.accent_color
                                  : MyTheme.font_grey),
                        ),
                        subtitle: Text(subtitle,
                            style: TextStyle(
                                color: suggestion.type != "search"
                                    ? MyTheme.font_grey
                                    : MyTheme.medium_grey)),
                      );
                    },
                    onSelected: (dynamic suggestion) {
                      _searchController.text = suggestion.query;
                      _searchKey = suggestion.query;
                      setState(() {});
                      _onSearchSubmit();
                    },
                    builder: (context, controller, focusNode) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xffE4E3E8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 63, 63, 63)
                                  .withOpacity(.12),
                              blurRadius: 10,
                              spreadRadius: 0.4,
                              offset: Offset(0.0, 3.0),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          obscureText: false,
                          decoration: searchContainer(
                              context,
                              AppLocalizations.of(context)!.search_here_ucf,
                              _onSearchSubmit),
                          //  buildAddressInputDecoration(context,
                          //     AppLocalizations.of(context)!.search_here_ucf),
                        ),
                      );
                    },
                  )),
            ),
          ),
        ]);
  }

  buildFilterDrawer() {
    return Directionality(
      textDirection:
          TextDirection.ltr, // ✅ Cố định LTR cho tiếng Việt
      child: Drawer(
        child: Container(
          padding: EdgeInsets.only(top: 50),
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.price_range_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .minimum_ucf,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.text_field_grey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.text_field_grey,
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        const Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.text_field_grey,
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        const Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                          Text(" - "),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .maximum_ucf,
                                    hintStyle: TextStyle(
                                        fontSize: 12.0,
                                        color: MyTheme.text_field_grey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.text_field_grey,
                                          width: 1.0),
                                      borderRadius: const BorderRadius.all(
                                        const Radius.circular(4.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: MyTheme.text_field_grey,
                                          width: 2.0),
                                      borderRadius: const BorderRadius.all(
                                        const Radius.circular(4.0),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(4.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.categories_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _filterCategoryList.length == 0
                          ? Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .no_category_is_available,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: buildFilterCategoryList(),
                            ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          AppLocalizations.of(context)!.brands_ucf,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _filterBrandList.length == 0
                          ? Container(
                              height: 100,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .no_brand_is_available,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: buildFilterBrandsList(),
                            ),
                    ]),
                  )
                ]),
              ),
              Container(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        setState(() {
                          _selectedCategories.clear();
                          _selectedBrands.clear();
                        });
                      },
                      child: Text(
                        'CLEAR',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        var min = _minPriceController.text.toString();
                        var max = _maxPriceController.text.toString();
                        bool apply = true;
                        if (min != "" && max != "") {
                          if (max.compareTo(min) < 0) {
                            ToastComponent.showDialog(
                              AppLocalizations.of(context)!
                                  .filter_screen_min_max_warning,
                            );
                            apply = false;
                          }
                        }

                        if (apply) {
                          _applyProductFilter();
                        }
                      },
                      child: Text(
                        'CLEAR',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildFilterBrandsList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterBrandList
            .map(
              (brand) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(brand.name),
                value: _selectedBrands.contains(brand.id),
                onChanged: (bool? value) {
                  if (value!) {
                    setState(() {
                      _selectedBrands.add(brand.id);
                    });
                  } else {
                    setState(() {
                      _selectedBrands.remove(brand.id);
                    });
                  }
                },
              ),
            )
            .toList()
      ],
    );
  }

  ListView buildFilterCategoryList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterCategoryList
            .map(
              (category) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(category.name),
                value: _selectedCategories.contains(category.id),
                onChanged: (bool? value) {
                  if (value!) {
                    setState(() {
                      _selectedCategories.clear();
                      _selectedCategories.add(category.id);
                    });
                  } else {
                    setState(() {
                      _selectedCategories.remove(category.id);
                    });
                  }
                },
              ),
            )
            .toList()
      ],
    );
  }

  Container buildProductList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildProductScrollableList(),
          )
        ],
      ),
    );
  }

  buildProductScrollableList() {
    if (_isProductInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onProductListRefresh,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.top > 40 ? 135 : 135
                  //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                  ),
              MasonryGridView.count(
                // 2
                //addAutomaticKeepAlives: true,
                itemCount: _productList.length,
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                padding:
                    EdgeInsets.only(top: 10, bottom: 10, left: 18, right: 18),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return ProductCard(
                    id: _productList[index].id,
                    slug: _productList[index].slug,
                    image: _productList[index].thumbnail_image,
                    name: _productList[index].name,
                    main_price: _productList[index].main_price,
                    stroked_price: _productList[index].stroked_price,
                    has_discount: _productList[index].has_discount,
                    discount: _productList[index].discount,
                    is_wholesale: _productList[index].is_wholesale ?? false,
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalProductData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_product_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  Container buildBrandList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildBrandScrollableList(),
          )
        ],
      ),
    );
  }

  buildBrandScrollableList() {
    if (_isBrandInitial && _brandList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_brandList.length > 0) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onBrandListRefresh,
        child: SingleChildScrollView(
          controller: _brandScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.top > 40 ? 126 : 135
                  //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
                  ),
              GridView.builder(
                // 2
                //addAutomaticKeepAlives: true,
                itemCount: _brandList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1),
                padding:
                    EdgeInsets.only(top: 20, bottom: 10, left: 18, right: 18),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return BrandSquareCard(
                    id: _brandList[index].id,
                    slug: _brandList[index].slug,
                    image: _brandList[index].logo,
                    name: _brandList[index].name,
                  );
                },
              )
            ],
          ),
        ),
      );
    } else if (_totalBrandData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_brand_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  Container buildShopList() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: buildShopScrollableList(),
          )
        ],
      ),
    );
  }

  buildShopScrollableList() {
    if (_isShopInitial && _shopList.length == 0) {
      return SingleChildScrollView(
          controller: _scrollController,
          child: ShimmerHelper()
              .buildSquareGridShimmer(scontroller: _scrollController));
    } else if (_totalShopData == 0) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_shop_is_available));
    } else {
      return Container(); // should never be happening
    }
  }

  InputDecoration searchContainer(
      BuildContext context, hintText, VoidCallback? onTap) {
    return InputDecoration(
        filled: true,
        suffixIcon: GestureDetector(
          onTap: onTap,
          child: Icon(Icons.search, color: Colors.grey.shade500, size: 25),
        ),
        fillColor: Color(0xffE4E3E8),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.grey_153),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.noColor, width: 0.5),
          borderRadius: const BorderRadius.all(
            const Radius.circular(8.0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.noColor, width: 1.0),
          borderRadius: const BorderRadius.all(
            const Radius.circular(8.0),
          ),
        ),
        contentPadding: EdgeInsets.only(left: 8.0, top: 10.0, bottom: 15.0));
  }
}
