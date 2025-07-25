import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:haxuvina/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_config.dart';
import '../../custom/box_decorations.dart';
import '../../custom/btn.dart';
import '../../custom/device_info.dart';
import '../../custom/lang_text.dart';
import '../../custom/quantity_input.dart';
import '../../custom/toast_component.dart';
import '../../data_model/product_details_response.dart';
import '../../helpers/color_helper.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../helpers/system_config.dart';
import '../../my_theme.dart';
import '../../presenter/cart_counter.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../../ui_elements/mini_product_card.dart';
import '../brand_products.dart';
import '../checkout/cart.dart';
import '../video_description_screen.dart';
import 'product_reviews.dart';
import 'widgets/product_slider_image_widget.dart';
import 'widgets/tappable_icon_widget.dart';

class ProductDetails extends StatefulWidget {
  final String slug;
  const ProductDetails({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  bool _showCopied = false;
  String? _appbarPriceString = ". . .";
  int _currentImage = 0;
  ScrollController _mainScrollController =
      ScrollController(initialScrollOffset: 0.0);
  ScrollController _colorScrollController = ScrollController();
  ScrollController _variantScrollController = ScrollController();
  ScrollController _imageScrollController = ScrollController();

  double _scrollPosition = 0.0;

  Animation? _colorTween;
  late AnimationController _ColorAnimationController;
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..enableZoom(false);
  double webViewHeight = 50.0;

  CarouselSliderController _carouselController = CarouselSliderController();
  late BuildContext loadingcontext;

  //init values

  bool _isInWishList = false;
  var _productDetailsFetched = false;
  DetailedProduct? _productDetails;
  var _productImageList = [];
  var _colorList = [];
  int _selectedColorIndex = 0;
  var _selectedChoices = [];
  var _choiceString = "";
  String? _variant = "";
  String? _totalPrice = "...";
  var _singlePrice;
  var _singlePriceString;
  int? _quantity = 1;
  int? _stock = 0;
  var _stock_txt;

  double opacity = 0;

  List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;

  @override
  void initState() {
    super.initState();
    quantityText.text = "${_quantity ?? 0}";
    controller;
    _ColorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));

    _colorTween = ColorTween(begin: Colors.transparent, end: Colors.white)
        .animate(_ColorAnimationController);

    _mainScrollController.addListener(() {
      _scrollPosition = _mainScrollController.position.pixels;

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;
        }
      }

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;

          if (100 > _scrollPosition) {
            opacity = 1;
          }
        }
      }

      setState(() {});
    });
    fetchAll();
  }

  fetchAll() {
    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }
    fetchRelatedProducts();
  }

  fetchProductDetails() async {
    try {
      print("▶️ fetchProductDetails slug=${widget.slug}");
      final resp = await ProductRepository().getProductDetails(
        slug: widget.slug,
        userId: is_logged_in.$ ? user_id.$ as int : 0,
      );
      if (resp.detailed_products != null &&
          resp.detailed_products!.isNotEmpty) {
        _productDetails = resp.detailed_products![0];
        setProductDetailValues();
      } else {
        ToastComponent.showDialog("Không tìm thấy sản phẩm");
      }
    } catch (e) {
      print("❌ fetchProductDetails error: $e");
      ToastComponent.showDialog("Không thể tải chi tiết sản phẩm");
    } finally {
      setState(() => _productDetailsFetched = true);
    }
  }

  fetchRelatedProducts() async {
    var relatedProductResponse =
        await ProductRepository().getFrequentlyBoughProducts(slug: widget.slug);
    _relatedProducts.addAll(relatedProductResponse.products!);
    _relatedProductInit = true;

    setState(() {});
  }

  setProductDetailValues() {
    if (_productDetails != null) {
      controller.loadHtmlString(makeHtml(_productDetails!.description!));
      _appbarPriceString = _productDetails!.price_high_low;
      _singlePrice = _productDetails!.calculable_price;
      _singlePriceString = _productDetails!.main_price;
      _stock = _productDetails!.current_stock;
      _productDetails!.photos.forEach((photo) {
        _productImageList.add(photo.path);
      });

      _productDetails!.choice_options.forEach((choice_opiton) {
        _selectedChoices.add(choice_opiton.options[0]);
      });
      _productDetails!.colors.forEach((color) {
        _colorList.add(color);
      });
      setChoiceString();
      fetchAndSetVariantWiseInfo(change_appbar_string: true);
      _productDetailsFetched = true;

      setState(() {});
    }
  }

  setChoiceString() {
    _choiceString = _selectedChoices.join(",").toString();
    print(_choiceString);
    setState(() {});
  }

  fetchWishListCheckInfo() async {
    var wishListCheckResponse =
        await WishListRepository().isProductInUserWishList(
      product_slug: widget.slug,
    );

    if (wishListCheckResponse.is_in_wishlist != null) {
      _isInWishList = wishListCheckResponse.is_in_wishlist!;
    } else {
      _isInWishList = false;
    }

    setState(() {});
  }

  addToWishList() async {
    var wishListCheckResponse =
        await WishListRepository().add(product_slug: widget.slug);

    _isInWishList = wishListCheckResponse.is_in_wishlist;
    setState(() {});
  }

  removeFromWishList() async {
    var wishListCheckResponse =
        await WishListRepository().remove(product_slug: widget.slug);

    _isInWishList = wishListCheckResponse.is_in_wishlist;
    setState(() {});
  }

  onWishTap() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    if (_isInWishList) {
      _isInWishList = false;
      setState(() {});
      removeFromWishList();
    } else {
      _isInWishList = true;
      setState(() {});
      addToWishList();
    }
  }

  setQuantity(quantity) {
    quantityText.text = "${quantity ?? 0}";
  }

  fetchAndSetVariantWiseInfo({bool change_appbar_string = true}) async {
    var color_string = _colorList.isNotEmpty
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    var variantResponse = await ProductRepository().getVariantWiseInfo(
      slug: widget.slug,
      color: color_string,
      variants: _choiceString,
      qty: _quantity,
    );

    if (variantResponse.variantData != null) {
      _stock = variantResponse.variantData!.stock;
      _stock_txt = variantResponse.variantData!.stockTxt;

      if (_quantity! > _stock!) {
        _quantity = _stock;
      }

      _variant = variantResponse.variantData!.variant;
      _totalPrice = variantResponse.variantData!.price;

      int pindex = 0;
      _productDetails!.photos.forEach((photo) {
        if (photo.variant == _variant &&
            (variantResponse.variantData!.image ?? "").isNotEmpty) {
          _currentImage = pindex;
          _carouselController.jumpToPage(pindex);
        }
        pindex++;
      });

      setQuantity(_quantity);
    } else {
      _stock = 0;
      _stock_txt = AppLocalizations.of(context)!.out_stock;
      _variant = '';
      _totalPrice = '0';
      _quantity = 0;
      setQuantity(_quantity);
    }

    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _currentImage = 0;
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _choiceString = "";
    _variant = "";
    _selectedColorIndex = 0;
    _quantity = 1;
    _productDetailsFetched = false;
    _isInWishList = false;
    setState(() {});
  }

  restProductDetailValues() {
    _appbarPriceString = " . . .";
    _productDetails = null;
    _productImageList.clear();
    _currentImage = 0;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  _onVariantChange(_choice_options_index, value) {
    _selectedChoices[_choice_options_index] = value;
    setChoiceString();
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndex = index;
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  onPressAddToCart(context, snackbar) {
    addToCart(mode: "add_to_cart", context: context, snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now", context: context);
  }

  addToCart({mode, BuildContext? context, snackbar = null}) async {
    if (!guest_checkout_status.$) {
      if (is_logged_in.$ == false) {
        context?.go("/users/login");
        return;
      }
    }

    var cartAddResponse = await CartRepository().getCartAddResponse(
        _productDetails!.id, _variant, user_id.$, _quantity);

    temp_user_id.$ = cartAddResponse.tempUserId;
    temp_user_id.save();

    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(
        cartAddResponse.message,
      );
      return;
    } else {
      Provider.of<CartCounter>(context!, listen: false).getCount();

      if (mode == "add_to_cart") {
        if (snackbar != null) {
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
        reset();
        fetchAll();
      } else if (mode == 'buy_now') {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Cart(has_bottom_nav: true);
        })).then((value) {
          onPopped(value);
        });
      }
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(setState) {
    setState(() {
      _showCopied = true;
    });
    Timer(Duration(seconds: 3), () {
      setState(() {
        _showCopied = false;
      });
    });
  }

  onPressShare(context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75,
                          height: 26,
                          color: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side:
                                  BorderSide(color: Colors.black, width: 1.0)),
                          child: Text(
                            AppLocalizations.of(context)!.copy_product_link_ucf,
                            style: TextStyle(
                              color: MyTheme.medium_grey,
                            ),
                          ),
                          onPressed: () {
                            onCopyTap(setState);
                            Clipboard.setData(ClipboardData(
                                text: _productDetails!.link ?? ""));
                            Clipboard.setData(ClipboardData(
                              text: _productDetails!.link!,
                            )).then((_) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Copied to clipboard"),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(milliseconds: 300),
                              ));
                            });
                          },
                        ),
                      ),
                      _showCopied
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.copied_ucf,
                                style: TextStyle(
                                    color: MyTheme.medium_grey, fontSize: 12),
                              ),
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75,
                          height: 26,
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side:
                                  BorderSide(color: Colors.black, width: 1.0)),
                          child: Text(
                            AppLocalizations.of(context)!.share_options_ucf,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            Share.share(_productDetails!.link!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                                color: MyTheme.font_grey, width: 1.0)),
                        child: Text(
                          LangText(context).local.close_all_capital,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          });
        });
  }

  loading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("${AppLocalizations.of(context)!.please_wait_ucf}"),
            ],
          ),
        );
      },
    );
  }

  showLoginWarning() {
    return ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    SnackBar _addedToCartSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)!.added_to_cart,
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.show_cart_all_capital,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Cart(has_bottom_nav: true);
          })).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
          extendBody: true,
          backgroundColor: MyTheme.mainColor,
          bottomNavigationBar: buildBottomAppBar(context, _addedToCartSnackbar),
          body: RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Colors.white,
            onRefresh: _onPageRefresh,
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: <Widget>[
                SliverAppBar(
                  elevation: 0,
                  scrolledUnderElevation: 0.0,
                  backgroundColor: MyTheme.mainColor,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: 355.0,
                  title: AnimatedOpacity(
                      opacity: _scrollPosition > 250 ? 1 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Container(
                          padding: EdgeInsets.only(left: 8),
                          width: DeviceInfo(context).width! / 2,
                          child: Text(
                            "${_productDetails != null ? _productDetails!.name : ''}",
                            style: TextStyle(
                                color: MyTheme.dark_font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ))),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Positioned.fill(
                          child: ProductSliderImageWidget(
                            productImageList: _productImageList,
                            currentImage: _currentImage,
                            carouselController: _carouselController,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 48, left: 33, right: 33),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) => InkWell(
                                  onTap: () {
                                    return Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    decoration: BoxDecorations
                                        .buildCircularButtonDecoration_for_productDetails(),
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: MyTheme.dark_font_grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return Cart(has_bottom_nav: true);
                                  })).then((value) {
                                    onPopped(value);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecorations
                                      .buildCircularButtonDecoration_for_productDetails(),
                                  width: 32,
                                  height: 32,
                                  padding: EdgeInsets.all(2),
                                  child: badges.Badge(
                                    position: badges.BadgePosition.topEnd(
                                      top: -6,
                                      end: -6,
                                    ),
                                    badgeStyle: badges.BadgeStyle(
                                      shape: badges.BadgeShape.circle,
                                      badgeColor: MyTheme.accent_color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    badgeAnimation: badges.BadgeAnimation.slide(
                                      toAnimate: true,
                                    ),
                                    stackFit: StackFit.loose,
                                    child: Center(
                                      child: Image.asset(
                                        "assets/cart.png",
                                        color: MyTheme.dark_font_grey,
                                        height: 16,
                                      ),
                                    ),
                                    badgeContent: Consumer<CartCounter>(
                                      builder: (context, cart, child) {
                                        return Text(
                                          "${cart.cartCounter}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              InkWell(
                                onTap: () {
                                  onPressShare(context);
                                },
                                child: TappableIconWidget(
                                  icon: Icons.share_outlined,
                                  color: MyTheme.dark_font_grey,
                                ),
                              ),
                              SizedBox(width: 15),
                              InkWell(
                                onTap: () {
                                  onWishTap();
                                },
                                child: TappableIconWidget(
                                  icon: Icons.favorite,
                                  color: _isInWishList
                                      ? Color.fromRGBO(230, 46, 4, 1)
                                      : MyTheme.dark_font_grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 20,
                            spreadRadius: 0.0,
                            offset: Offset(
                                0.0, 0.0),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _productDetails != null
                                    ? Text(
                                        _productDetails!.name!,
                                        style: TextStyle(
                                            color: Color(0xff3E4447),
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'BeVietnamPro',
                                            fontSize: 13),
                                        maxLines: 2,
                                      )
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                                SizedBox(height: 13),
                                _productDetails != null
                                    ? buildRatingAndWishButtonRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                                if (_productDetails != null &&
                                    _productDetails!.estShippingTime != null &&
                                    _productDetails!.estShippingTime! > 0)
                                  _productDetails != null
                                      ? buildShippingTime()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                SizedBox(height: 12),
                                _productDetails != null
                                    ? buildMainPriceRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                                SizedBox(height: 14),
                                Visibility(
                                  visible: club_point_addon_installed.$,
                                  child: _productDetails != null
                                      ? buildClubPointRow()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                ),
                                SizedBox(height: 9),
                                _productDetails != null
                                    ? buildBrandRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                          height: 50.0,
                                        ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            child: Column(
                              children: [
                                SizedBox(height: 11),
                                _productDetails != null
                                    ? buildChoiceOptionList()
                                    : buildVariantShimmers(),
                                _productDetails != null
                                    ? (_colorList.length > 0
                                        ? buildColorRow()
                                        : Container())
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                                SizedBox(
                                  height: 20,
                                ),
                                Visibility(
                                  visible: whole_sale_addon_installed.$,
                                  child: _productDetails != null
                                      ? _productDetails!.wholesale.isNotEmpty
                                          ? buildWholeSaleQuantityPrice()
                                          : SizedBox.shrink()
                                      : ShimmerHelper().buildBasicShimmer(
                                          height: 30.0,
                                        ),
                                ),
                                _productDetails != null
                                    ? buildQuantityRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 27,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _productDetails != null
                                ? buildTotalPriceRow()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                          SizedBox(
                            height: 10,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                spreadRadius: 0,
                                blurRadius: 16,
                                offset:
                                    Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  20.0,
                                  16.0,
                                  0.0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.description_ucf,
                                  style: TextStyle(
                                      color: Color(0xff3E4447),
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  0.0,
                                  8.0,
                                  8.0,
                                ),
                                child: _productDetails != null
                                    ? buildExpandableDescription()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 8.0),
                                        child:
                                            ShimmerHelper().buildBasicShimmer(
                                          height: 60.0,
                                        )),
                              ),
                            ],
                          ),
                        ),
                        if (_productDetails?.downloads != null)
                          Column(
                            children: [
                              SizedBox(
                                height: 16,
                              ),
                              InkWell(
                                onTap: () async {
                                  var url = Uri.parse(
                                      _productDetails?.downloads ?? "");
                                  launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                },
                                child: Container(
                                  color: MyTheme.white,
                                  height: 48,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18.0,
                                      14.0,
                                      18.0,
                                      14.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .downloads_ucf,
                                          style: TextStyle(
                                              color: MyTheme.dark_font_grey,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Spacer(),
                                        Image.asset(
                                          "assets/arrow.png",
                                          height: 11,
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(
                          height: 16,
                        ),
                        InkWell(
                          onTap: () {
                            if (_productDetails!.video_link == "") {
                              ToastComponent.showDialog(
                                AppLocalizations.of(context)!
                                    .video_not_available,
                              );
                              return;
                            }

                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return VideoDescription(
                                url: _productDetails!.video_link,
                              );
                            })).then((value) {
                              onPopped(value);
                            });
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 16,
                                  offset: Offset(
                                      0, 0),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.video_ucf,
                                    style: TextStyle(
                                        color: Color(0xff3E4447),
                                        fontSize: 13,
                                        fontFamily: 'BeVietnamPro',
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    color: Color(0xff6B7377),
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ProductReviews(id: _productDetails!.id);
                            })).then((value) {
                              onPopped(value);
                            });
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 16,
                                  offset: Offset(
                                      0, 0),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.reviews_ucf,
                                    style: TextStyle(
                                        color: Color(0xff3E4447),
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18.0,
                        22.0,
                        18.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .products_you_may_also_like,
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    buildProductsMayLikeList()
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      height: 83,
                    )
                  ]),
                ),
              ],
            ),
          )),
    );
  }

  Widget buildTotalPriceRow() {
    return Container(
      height: 40,
      color: Color(0xffFEF0D7),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            child: Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: Container(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.total_price_ucf,
                  style: TextStyle(color: Color(0xff6B7377), fontSize: 10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              SystemConfig.systemCurrency != null
                  ? _totalPrice.toString().replaceAll(
                      SystemConfig.systemCurrency!.code!,
                      SystemConfig.systemCurrency!.symbol!)
                  : SystemConfig.systemCurrency!.symbol! +
                      _totalPrice.toString(),
              style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Row buildQuantityRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.quantity_ucf,
              style: TextStyle(
                  color: Color(0xff6B7377), fontFamily: 'BeVietnamPro'),
            ),
          ),
        ),
        Container(
          height: 30,
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              buildQuantityDownButton(),
              SizedBox(
                width: 1,
              ),
              Container(
                  width: 30,
                  child: Center(
                      child: QuantityInputField.show(quantityText,
                          isDisable: _quantity == 0, onSubmitted: () {
                    _quantity = int.parse(quantityText.text);
                    print(_quantity);
                    fetchAndSetVariantWiseInfo();
                  }))),
              buildQuantityUpButton()
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "$_stock_txt",
            style: TextStyle(color: Color(0xff6B7377), fontSize: 14),
          ),
        ),
      ],
    );
  }

  TextEditingController quantityText = TextEditingController(text: "0");

  Padding buildVariantShimmers() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        0.0,
        8.0,
        0.0,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetails!.choice_options!.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetails!.choice_options, index),
        );
      },
    );
  }

  buildChoiceOpiton(choice_options, choice_options_index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0.0,
        14.0,
        0.0,
        0.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: Container(
              width: 75,
              child: Text(
                choice_options[choice_options_index].title,
                style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width - (107 + 45),
            child: Scrollbar(
              controller: _variantScrollController,
              child: Wrap(
                children: List.generate(
                    choice_options[choice_options_index].options.length,
                    (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          width: 75,
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: buildChoiceItem(
                              choice_options[choice_options_index]
                                  .options[index],
                              choice_options_index,
                              index),
                        ))),
              ),
            ),
          )
        ],
      ),
    );
  }

  buildChoiceItem(option, choice_options_index, index) {
    return Padding(
      padding: app_language_rtl.$!
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choice_options_index, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: _selectedChoices[choice_options_index] == option
                    ? MyTheme.accent_color
                    : MyTheme.noColor,
                width: 1.5),
            borderRadius: BorderRadius.circular(3.0),
            color: MyTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0.0, 3.0),
              )
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                    color: _selectedChoices[choice_options_index] == option
                        ? MyTheme.accent_color
                        : Color.fromRGBO(224, 224, 225, 1),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.color_ucf,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          alignment: app_language_rtl.$!
              ? Alignment.centerRight
              : Alignment.centerLeft,
          height: 40,
          width: MediaQuery.of(context).size.width - (107 + 44),
          child: Scrollbar(
            controller: _colorScrollController,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(
                  width: 10,
                );
              },
              itemCount: _colorList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildColorItem(index),
                  ],
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget buildColorItem(index) {
    return InkWell(
      onTap: () {
        _onColorChange(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        width: _selectedColorIndex == index ? 28 : 20,
        height: _selectedColorIndex == index ? 28 : 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: ColorHelper.getColorFromColorCode(_colorList[index]),
          boxShadow: [
            _selectedColorIndex == index
                ? BoxShadow(
                    color: Colors.black.withOpacity(
                        _selectedColorIndex == index ? 0.25 : 0.12),
                    blurRadius: 10,
                    spreadRadius: 2.0,
                    offset: Offset(0.0, 6.0),
                  )
                : BoxShadow(
                    color: Colors.black.withOpacity(
                        _selectedColorIndex == index ? 0.25 : 0.16),
                    blurRadius: 6,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 3.0),
                  )
          ],
        ),
        child: _selectedColorIndex == index
            ? buildColorCheckerContainer()
            : Container(
                height: 25,
              ),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          "assets/white_tick.png",
          width: 16,
          height: 16,
        ));
  }

  Widget buildWholeSaleQuantityPrice() {
    return DataTable(
      columnSpacing: DeviceInfo(context).width! * 0.125,
      columns: [
        DataColumn(
            label: Text(LangText(context).local.min_qty_ucf,
                style: TextStyle(fontSize: 12, color: MyTheme.dark_grey))),
        DataColumn(
            label: Text(LangText(context).local.max_qty_ucf,
                style: TextStyle(fontSize: 12, color: MyTheme.dark_grey))),
        DataColumn(
            label: Text(LangText(context).local.unit_price_ucf,
                style: TextStyle(fontSize: 12, color: MyTheme.dark_grey))),
      ],
      rows: List<DataRow>.generate(
        _productDetails!.wholesale.length,
        (index) {
          return DataRow(cells: <DataCell>[
            DataCell(
              Text(
                '${_productDetails!.wholesale[index].minQty.toString()}',
                style: TextStyle(
                    color: Color.fromRGBO(152, 152, 153, 1), fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                '${_productDetails!.wholesale[index].maxQty.toString()}',
                style: TextStyle(
                    color: Color.fromRGBO(152, 152, 153, 1), fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                convertPrice(
                    _productDetails!.wholesale[index].price.toString()),
                style: TextStyle(
                    color: Color.fromRGBO(152, 152, 153, 1), fontSize: 12),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget buildClubPointRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 120),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Color(0xffFFF4E8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded( // 👈 bọc bên trái lại để không bị tràn
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/club_point.png",
                    width: 18,
                    height: 12,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.club_point_ucf,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xff6B7377),
                        fontSize: 10,
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _productDetails!.earn_point.toString(),
              style: TextStyle(color: Color(0xffF7941D), fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Row buildMainPriceRow() {
    return Row(
      children: [
        Text(
          SystemConfig.systemCurrency != null
              ? _singlePriceString.replaceAll(SystemConfig.systemCurrency!.code,
                  SystemConfig.systemCurrency!.symbol)
              : _singlePriceString,
          style: TextStyle(
              color: Color(0xffE62E04),
              fontFamily: 'BeVietnamPro',
              fontSize: 16.0,
              fontWeight: FontWeight.bold),
        ),
        Visibility(
          visible: _productDetails!.has_discount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
                SystemConfig.systemCurrency != null
                    ? _productDetails!.stroked_price!.replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : _productDetails!.stroked_price!,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xffA8AFB3),
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                )),
          ),
        ),
        Visibility(
          visible: _productDetails!.has_discount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              "${_productDetails!.discount}",
              style: TextStyle(
                  fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Text(
          "/${_productDetails!.unit}",
          style: TextStyle(
              color: MyTheme.accent_color,
              fontSize: 16.0,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Container(
        height: kToolbarHeight +
            statusBarHeight -
            (MediaQuery.of(context).viewPadding.top > 40 ? 32.0 : 16.0),
        child: Container(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(top: 22.0),
              child: Text(
                _appbarPriceString!,
                style: TextStyle(fontSize: 16, color: MyTheme.font_grey),
              ),
            )),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey),
            onPressed: () {
              onPressShare(context);
            },
          ),
        ),
      ],
    );
  }

  Widget buildBottomAppBar(BuildContext context, _addedToCartSnackbar) {
    return BottomNavigationBar(
      backgroundColor: MyTheme.white.withOpacity(0.9),
      items: [
        BottomNavigationBarItem(
          backgroundColor: Colors.transparent,
          label: '',
          icon: InkWell(
            onTap: () {
              onPressAddToCart(context, _addedToCartSnackbar);
            },
            child: Container(
              margin: EdgeInsets.only(
                left: 23,
                right: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.accent_color,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.accent_color_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  )
                ],
              ),
              height: 50,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.add_to_cart_ucf,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        BottomNavigationBarItem(
          label: "",
          icon: InkWell(
            onTap: () {
              onPressBuyNow(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 14, right: 23),
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.golden,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.golden_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.buy_now_ucf,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  buildRatingAndWishButtonRow() {
    return Row(
      children: [
        RatingBar(
          itemSize: 15.0,
          ignoreGestures: true,
          initialRating: double.parse(_productDetails!.rating.toString()),
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: Colors.amber),
            half: Icon(Icons.star_half, color: Colors.amber),
            empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
          ),
          itemPadding: EdgeInsets.only(right: 1.0),
          onRatingUpdate: (rating) {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "(" + _productDetails!.rating_count.toString() + ")",
            style: TextStyle(
                color: Color.fromRGBO(152, 152, 153, 1), fontSize: 10),
          ),
        ),
      ],
    );
  }

  buildShippingTime() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            LangText(context).local.estimate_shipping_time_ucf,
            style: TextStyle(
                color: Color.fromRGBO(152, 152, 153, 1), fontSize: 10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "${_productDetails!.estShippingTime}  ${LangText(context).local.days_ucf}",
            style: TextStyle(
                color: Color.fromRGBO(152, 152, 153, 1), fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget buildBrandRow() {
    final brand = _productDetails?.brand;
    if (brand == null || (brand.id ?? 0) <= 0 || brand.name == null) {
      return SizedBox.shrink();
    }
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return BrandProducts(slug: brand.slug ?? "");
        }));
      },
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: Container(
              width: 75,
              child: Text(
                AppLocalizations.of(context)!.brand_ucf,
                style: TextStyle(
                    color: Color(0xff6B7377),
                    fontSize: 10,
                    fontFamily: 'BeVietnamPro'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              brand.name!,
              style: TextStyle(
                  color: Color(0xff3E4447),
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  buildExpandableDescription() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: DeviceInfo(context).width,
            height: webViewHeight,
            child: WebViewWidget(
              controller: controller,
            ),
          ),
          Btn.basic(
              onPressed: () async {
                if (webViewHeight == 50) {
                  webViewHeight = double.parse(
                    (await controller.runJavaScriptReturningResult(
                            "document.getElementById('scaled-frame').clientHeight"))
                        .toString(),
                  );
                  print(webViewHeight);
                } else {
                  webViewHeight = 50;
                }
                setState(() {});
              },
              child: Text(
                webViewHeight == 50
                    ? LangText(context).local.view_more
                    : LangText(context).local.less,
                style: TextStyle(color: Color(0xff0077B6)),
              ))
        ],
      ),
    );
  }

  buildProductsMayLikeList() {
    if (_relatedProductInit == false && _relatedProducts.length == 0) {
      return Row(
        children: [
          Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
        ],
      );
    } else if (_relatedProducts.length > 0) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 248,
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(
              width: 16,
            ),
            padding: const EdgeInsets.all(16),
            itemCount: _relatedProducts.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return MiniProductCard(
                  id: _relatedProducts[index].id,
                  slug: _relatedProducts[index].slug,
                  image: _relatedProducts[index].thumbnail_image,
                  name: _relatedProducts[index].name,
                  main_price: _relatedProducts[index].main_price,
                  stroked_price: _relatedProducts[index].stroked_price,
                  is_wholesale: _relatedProducts[index].is_wholesale ?? false,
                  discount: _relatedProducts[index].discount,
                  has_discount: _relatedProducts[index].has_discount);
            },
          ),
        ),
      );
    } else {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.no_related_product,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
  }

  buildQuantityUpButton() => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.16),
              blurRadius: 6,
              spreadRadius: 0.0,
              offset: Offset(0.0, 3.0),
            ),
          ],
        ),
        width: 36,
        child: IconButton(
            icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
            onPressed: () {
              if (_quantity! < _stock!) {
                _quantity = (_quantity!) + 1;
                setState(() {});
                fetchAndSetVariantWiseInfo();
              }
            }),
      );

  buildQuantityDownButton() => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            blurRadius: 6,
            spreadRadius: 0.0,
            offset: Offset(0.0, 3.0),
          ),
        ],
      ),
      width: 30,
      child: IconButton(
          icon: Center(
              child: Icon(Icons.remove, size: 16, color: Color(0xff707070))),
          onPressed: () {
            if (_quantity! > 1) {
              _quantity = _quantity! - 1;
              setState(() {});
              fetchAndSetVariantWiseInfo();
            }
          }));

  buildProductImageSection() {
    if (_productImageList.length == 0) {
      return Row(
        children: [
          Container(
            width: 40,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 190.0,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: 64,
            child: Scrollbar(
              controller: _imageScrollController,
              thumbVisibility: false,
              thickness: 4.0,
              child: Padding(
                padding: app_language_rtl.$!
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: ListView.builder(
                    itemCount: _productImageList.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      int itemIndex = index;
                      return GestureDetector(
                        onTap: () {
                          _currentImage = itemIndex;
                          print(_currentImage);
                          setState(() {});
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _currentImage == itemIndex
                                    ? MyTheme.accent_color
                                    : Color.fromRGBO(112, 112, 112, .3),
                                width: _currentImage == itemIndex ? 2 : 1),
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: _productImageList[index],
                                fit: BoxFit.contain,
                              )),
                        ),
                      );
                    }),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              openPhotoDialog(context, _productImageList[_currentImage]);
            },
            child: Container(
              height: 250,
              width: MediaQuery.of(context).size.width - 96,
              child: Container(
                  child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder_rectangle.png',
                image: _productImageList[_currentImage],
                fit: BoxFit.scaleDown,
              )),
            ),
          ),
        ],
      );
    }
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: Stack(
              children: [
                PhotoView(
                  enableRotation: true,
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                  imageProvider: NetworkImage(path),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: MyTheme.medium_grey_50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: MyTheme.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );

  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>

<head>

<meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="${AppConfig.RAW_BASE_URL}/public/assets/css/vendors.css">
  <style>
  *{
  margin:0 !important;
  padding:0 !important;
  }

    #scaled-frame {
    }
  </style>
</head>

<body id="main_id">
  <div id="scaled-frame">
$string
  </div>
</body>

</html>
""";
  }
}
