import 'package:haxuvina/custom/box_decorations.dart';
import 'package:haxuvina/custom/btn.dart';
import 'package:haxuvina/custom/lang_text.dart';
import 'package:haxuvina/custom/toast_component.dart';
import 'package:haxuvina/data_model/city_response.dart';
import 'package:haxuvina/data_model/country_response.dart';
import 'package:haxuvina/data_model/state_response.dart';
import 'package:haxuvina/helpers/shared_value_helper.dart';
import 'package:haxuvina/helpers/shimmer_helper.dart';
import 'package:haxuvina/my_theme.dart';
import 'package:haxuvina/repositories/address_repository.dart';
import 'package:haxuvina/screens/map_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haxuvina/gen_l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class Address extends StatefulWidget {
  Address({Key? key, this.from_shipping_info = false}) : super(key: key);
  bool from_shipping_info;

  @override
  _AddressState createState() => _AddressState();
}

class _AddressState extends State<Address> {
  ScrollController _mainScrollController = ScrollController();

  int? _default_shipping_address = 0;
  City? _selected_city;
  Country? _selected_country;
  MyState? _selected_state;

  bool _isInitial = true;
  List<dynamic> _shippingAddressList = [];

  //controllers for add purpose
  TextEditingController _addressController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _countryController = TextEditingController();

  //for update purpose
  List<TextEditingController> _addressControllerListForUpdate = [];
  List<TextEditingController> _phoneControllerListForUpdate = [];
  List<TextEditingController> _cityControllerListForUpdate = [];
  List<TextEditingController> _stateControllerListForUpdate = [];
  List<TextEditingController> _countryControllerListForUpdate = [];
  List<City?> _selected_city_list_for_update = [];
  List<MyState?> _selected_state_list_for_update = [];
  List<Country> _selected_country_list_for_update = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  fetchAll() {
    fetchShippingAddressList();

    setState(() {});
  }

  fetchShippingAddressList() async {
    // print("enter fetchShippingAddressList");
    var addressResponse = await AddressRepository().getAddressList();
    _shippingAddressList.addAll(addressResponse.addresses);
    setState(() {
      _isInitial = false;
    });
    if (_shippingAddressList.length > 0) {
      var count = 0;
      _shippingAddressList.forEach((address) {
        if (address.set_default == 1) {
          _default_shipping_address = address.id;
        }
        _addressControllerListForUpdate
            .add(TextEditingController(text: address.address));
        _phoneControllerListForUpdate
            .add(TextEditingController(text: address.phone));
        _countryControllerListForUpdate
            .add(TextEditingController(text: address.country_name));
        _stateControllerListForUpdate
            .add(TextEditingController(text: address.state_name));
        _cityControllerListForUpdate
            .add(TextEditingController(text: address.city_name));
        _selected_country_list_for_update
            .add(Country(id: address.country_id, name: address.country_name));
        _selected_state_list_for_update
            .add(MyState(id: address.state_id, name: address.state_name));
        _selected_city_list_for_update
            .add(City(id: address.city_id, name: address.city_name));
      });

      // print("fetchShippingAddressList");
    }

    setState(() {});
  }

  reset() {
    _default_shipping_address = 0;
    _shippingAddressList.clear();
    _isInitial = true;

    _addressController.clear();
    _phoneController.clear();

    _countryController.clear();
    _stateController.clear();
    _cityController.clear();

    //update-ables
    _addressControllerListForUpdate.clear();
    _phoneControllerListForUpdate.clear();
    _countryControllerListForUpdate.clear();
    _stateControllerListForUpdate.clear();
    _cityControllerListForUpdate.clear();
    _selected_city_list_for_update.clear();
    _selected_state_list_for_update.clear();
    _selected_country_list_for_update.clear();
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  afterAddingAnAddress() {
    reset();
    fetchAll();
  }

  afterDeletingAnAddress() {
    reset();
    fetchAll();
  }

  afterUpdatingAnAddress() {
    reset();
    fetchAll();
  }

  onAddressSwitch(index) async {
    var addressMakeDefaultResponse =
        await AddressRepository().getAddressMakeDefaultResponse(index);

    if (addressMakeDefaultResponse.result == false) {
      ToastComponent.showDialog(
        addressMakeDefaultResponse.message,
      );
      return;
    }

    ToastComponent.showDialog(
      addressMakeDefaultResponse.message,
    );

    setState(() {
      _default_shipping_address = index;
    });
  }

  onPressDelete(id) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: EdgeInsets.only(
                  top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
              content: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!
                      .are_you_sure_to_remove_this_address,
                  maxLines: 3,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
                ),
              ),
              actions: [
                Btn.basic(
                  child: Text(
                    AppLocalizations.of(context)!.cancel_ucf,
                    style: TextStyle(color: MyTheme.medium_grey),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                Btn.basic(
                  color: MyTheme.soft_accent_color,
                  child: Text(
                    AppLocalizations.of(context)!.confirm_ucf,
                    style: TextStyle(color: MyTheme.dark_grey),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    confirmDelete(id);
                  },
                ),
              ],
            ));
  }

  confirmDelete(id) async {
    var addressDeleteResponse =
        await AddressRepository().getAddressDeleteResponse(id);

    if (addressDeleteResponse.result == false) {
      ToastComponent.showDialog(
        addressDeleteResponse.message,
      );
      return;
    }

    ToastComponent.showDialog(
      addressDeleteResponse.message,
    );

    afterDeletingAnAddress();
  }

  onAddressAdd(context) async {
    var address = _addressController.text.toString();
    var phone = _phoneController.text.toString();

    if (address == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_address_ucf,
      );
      return;
    }

    if (_selected_country == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.select_a_country,
      );
      return;
    }

    if (_selected_state == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.select_a_state,
      );
      return;
    }

    if (_selected_city == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.select_a_city,
      );
      return;
    }

    var addressAddResponse = await AddressRepository().getAddressAddResponse(
        address: address,
        country_id: _selected_country!.id,
        state_id: _selected_state!.id,
        city_id: _selected_city!.id,
        phone: phone);

    if (addressAddResponse.result == false) {
      ToastComponent.showDialog(
        addressAddResponse.message,
      );
      return;
    }

    ToastComponent.showDialog(
      addressAddResponse.message,
    );

    Navigator.of(context, rootNavigator: true).pop();
    afterAddingAnAddress();
  }

  onAddressUpdate(context, index, id) async {
    var address = _addressControllerListForUpdate[index].text.toString();
    var phone = _phoneControllerListForUpdate[index].text.toString();

    if (address == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_address_ucf,
      );
      return;
    }

    if (_selected_state_list_for_update[index] == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.select_a_state,
      );
      return;
    }

    if (_selected_city_list_for_update[index] == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.select_a_city,
      );
      return;
    }

    var addressUpdateResponse = await AddressRepository()
        .getAddressUpdateResponse(
            id: id,
            address: address,
            country_id: _selected_country_list_for_update[index].id,
            state_id: _selected_state_list_for_update[index]!.id,
            city_id: _selected_city_list_for_update[index]!.id,
            phone: phone);

    if (addressUpdateResponse.result == false) {
      ToastComponent.showDialog(
        addressUpdateResponse.message,
      );
      return;
    }

    ToastComponent.showDialog(
      addressUpdateResponse.message,
    );

    Navigator.of(context, rootNavigator: true).pop();
    afterUpdatingAnAddress();
  }

  onSelectCountryDuringAdd(country, setModalState) {
    if (_selected_country != null && country.id == _selected_country!.id) {
      setModalState(() {
        _countryController.text = country.name;
      });
      return;
    }
    _selected_country = country;
    _selected_state = null;
    _selected_city = null;
    setState(() {});

    setModalState(() {
      _countryController.text = country.name;
      _stateController.text = "";
      _cityController.text = "";
    });
  }

  onSelectStateDuringAdd(state, setModalState) {
    if (_selected_state != null && state.id == _selected_state!.id) {
      setModalState(() {
        _stateController.text = state.name;
      });
      return;
    }
    _selected_state = state;
    _selected_city = null;
    setState(() {});
    setModalState(() {
      _stateController.text = state.name;
      _cityController.text = "";
    });
  }

  onSelectCityDuringAdd(city, setModalState) {
    if (_selected_city != null && city.id == _selected_city!.id) {
      setModalState(() {
        _cityController.text = city.name;
      });
      return;
    }
    _selected_city = city;
    setModalState(() {
      _cityController.text = city.name;
    });
  }

  onSelectCountryDuringUpdate(index, country, setModalState) {
    if (country.id == _selected_country_list_for_update[index].id) {
      setModalState(() {
        _countryControllerListForUpdate[index].text = country.name;
      });
      return;
    }
    _selected_country_list_for_update[index] = country;
    _selected_state_list_for_update[index] = null;
    _selected_city_list_for_update[index] = null;
    setState(() {});

    setModalState(() {
      _countryControllerListForUpdate[index].text = country.name;
      _stateControllerListForUpdate[index].text = "";
      _cityControllerListForUpdate[index].text = "";
    });
  }

  onSelectStateDuringUpdate(index, state, setModalState) {
    if (_selected_state_list_for_update[index] != null &&
        state.id == _selected_state_list_for_update[index]!.id) {
      setModalState(() {
        _stateControllerListForUpdate[index].text = state.name;
      });
      return;
    }
    _selected_state_list_for_update[index] = state;
    _selected_city_list_for_update[index] = null;
    setState(() {});
    setModalState(() {
      _stateControllerListForUpdate[index].text = state.name;
      _cityControllerListForUpdate[index].text = "";
    });
  }

  onSelectCityDuringUpdate(index, city, setModalState) {
    if (_selected_city_list_for_update[index] != null &&
        city.id == _selected_city_list_for_update[index]!.id) {
      setModalState(() {
        _cityControllerListForUpdate[index].text = city.name;
      });
      return;
    }
    _selected_city_list_for_update[index] = city;
    setModalState(() {
      _cityControllerListForUpdate[index].text = city.name;
    });
  }

  // Method to set Vietnam as default country
  Future<void> _setDefaultCountryToVietnam(StateSetter setModalState) async {
    try {
      var countryResponse = await AddressRepository().getCountryList();
      if (countryResponse.countries != null) {
        // Try to find Vietnam in the country list
        Country? vietnam;
        for (var country in countryResponse.countries!) {
          if (country.name != null &&
              (country.name!.toLowerCase().contains("vietnam") ||
               country.name!.toLowerCase().contains("việt nam") ||
               country.name!.toLowerCase().contains("viet nam"))) {
            vietnam = country;
            break;
          }
        }

        if (vietnam != null && vietnam.id != null) {
          _selected_country = vietnam;
          setModalState(() {
            _countryController.text = vietnam!.name ?? "";
          });
        }
      }
    } catch (e) {
      print("Error setting default country: $e");
    }
  }

  _tabOption(int index, listIndex) {
    switch (index) {
      case 0:
        buildShowUpdateFormDialog(context, listIndex);
        break;
      case 1:
        onPressDelete(_shippingAddressList[listIndex].id);
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return MapLocation(address: _shippingAddressList[listIndex]);
        })).then((value) {
          onPopped(value);
        });
        //deleteProduct(productId);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        bottomNavigationBar: buildBottomAppBar(context),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onRefresh,
          displacement: 0,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverList(
                  delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 05, 20, 16),
                  child: Btn.minWidthFixHeight(
                    minWidth: MediaQuery.of(context).size.width - 16,
                    height: 90,
                    color: Color(0xffFEF0D7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                            color: Colors.amber.shade600, width: 1.0)),
                    child: Column(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.no_address_is_added}",
                          style: TextStyle(
                              fontSize: 13,
                              color: MyTheme.dark_font_grey,
                              fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.add_sharp,
                          color: MyTheme.accent_color,
                          size: 30,
                        ),
                      ],
                    ),
                    onPressed: () {
                      buildShowAddFormDialog(context);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: buildAddressList(),
                ),
                SizedBox(
                  height: 100,
                )
              ]))
            ],
          ),
        ));
  }

// Alart Dialog
  Future buildShowAddFormDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setModalState /*You can rename this!*/) {
            // Set Vietnam as default country when dialog opens
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _setDefaultCountryToVietnam(setModalState);
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 23.0, left: 20.0, right: 20.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                            "${AppLocalizations.of(context)!.address_ucf} *",
                            style: TextStyle(
                                color: Color(0xff3E4447),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _addressController,
                            autofocus: false,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: buildAddressInputDecoration(
                                context,
                                AppLocalizations.of(context)!
                                    .enter_address_ucf),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.country_ucf} *",
                            style: TextStyle(
                                color: Color(0xff3E4447),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            controller: _countryController,
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                obscureText: false,
                                decoration: buildAddressInputDecoration(
                                    context,
                                    AppLocalizations.of(context)!
                                        .enter_country_ucf),
                              );
                            },
                            suggestionsCallback: (name) async {
                              var countryResponse = await AddressRepository()
                                  .getCountryList(name: name);
                              return countryResponse.countries;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_countries_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic country) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  country.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {
                              onSelectCountryDuringAdd(value, setModalState);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.state_ucf} *",
                            style: TextStyle(
                                color: Color(0xff3E4447),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                obscureText: false,
                                decoration: buildAddressInputDecoration(
                                    context,
                                    AppLocalizations.of(context)!
                                        .enter_state_ucf),
                              );
                            },
                            controller: _stateController,
                            suggestionsCallback: (name) async {
                              if (_selected_country == null) {
                                var stateResponse = await AddressRepository()
                                    .getStateListByCountry(); // blank response
                                return stateResponse.states;
                              }
                              var stateResponse = await AddressRepository()
                                  .getStateListByCountry(
                                      country_id: _selected_country!.id,
                                      name: name);
                              return stateResponse.states;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_states_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic state) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  state.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {
                              onSelectStateDuringAdd(value, setModalState);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.city_ucf} *",
                            style: TextStyle(
                                color: Color(0xff3E4447),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            controller: _cityController,
                            suggestionsCallback: (name) async {
                              if (_selected_state == null) {
                                var cityResponse = await AddressRepository()
                                    .getCityListByState(); // blank response
                                return cityResponse.cities;
                              }
                              var cityResponse = await AddressRepository()
                                  .getCityListByState(
                                      state_id: _selected_state!.id,
                                      name: name);
                              return cityResponse.cities;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_cities_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic city) {
                              //print(suggestion.toString());
                              return ListTile(
                                dense: true,
                                title: Text(
                                  city.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {
                              onSelectCityDuringAdd(value, setModalState);
                            },
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                obscureText: false,
                                decoration: buildAddressInputDecoration(
                                    context,
                                    AppLocalizations.of(context)!
                                        .enter_city_ucf),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(AppLocalizations.of(context)!.phone_ucf,
                            style: TextStyle(
                                color: Color(0xff3E4447),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _phoneController,
                            autofocus: false,
                            decoration: buildAddressInputDecoration(
                                context,
                                AppLocalizations.of(context)!
                                    .enter_phone_number),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            side: BorderSide(
                                color: MyTheme.light_grey, width: 1)),
                        child: Text(
                          LangText(context).local.close_ucf,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 28.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          LangText(context).local.add_ucf,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          onAddressAdd(context);
                        },
                      ),
                    )
                  ],
                )
              ],
            );
          });
        });
  }

  InputDecoration buildAddressInputDecoration(BuildContext context, hintText) {
    return InputDecoration(
        filled: true,
        fillColor: Color(0xffF6F7F8),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 12.0, color: Color(0xff999999)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.noColor, width: 0.5),
          borderRadius: const BorderRadius.all(
            const Radius.circular(6.0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.noColor, width: 1.0),
          borderRadius: const BorderRadius.all(
            const Radius.circular(6.0),
          ),
        ),
        contentPadding: EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0));
  }

  Future buildShowUpdateFormDialog(BuildContext context, index) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setModalState /*You can rename this!*/) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.address_ucf} *",
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 55,
                          child: TextField(
                            controller: _addressControllerListForUpdate[index],
                            autofocus: false,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: buildAddressInputDecoration(
                                context,
                                AppLocalizations.of(context)!
                                    .enter_address_ucf),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.country_ucf} *",
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            controller: _countryControllerListForUpdate[index],
                            suggestionsCallback: (name) async {
                              var countryResponse = await AddressRepository()
                                  .getCountryList(name: name);
                              return countryResponse.countries;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_countries_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic country) {
                              //print(suggestion.toString());
                              return ListTile(
                                dense: true,
                                title: Text(
                                  country.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {},

                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.state_ucf} *",
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            controller: _stateControllerListForUpdate[index],
                            suggestionsCallback: (name) async {
                              var stateResponse = await AddressRepository()
                                  .getStateListByCountry(
                                      country_id:
                                          _selected_country_list_for_update[
                                                  index]
                                              .id,
                                      name: name);
                              return stateResponse.states;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_states_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic state) {
                              //print(suggestion.toString());
                              return ListTile(
                                dense: true,
                                title: Text(
                                  state.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            // noItemsFoundBuilder: (context) {
                            //   return Container(
                            //     height: 50,
                            //     child: Center(
                            //         child: Text(
                            //             AppLocalizations.of(context)!
                            //                 .no_state_available,
                            //             style: TextStyle(
                            //                 color: MyTheme.medium_grey))),
                            //   );
                            // },
                            // onSuggestionSelected: (dynamic state) {
                            //   onSelectStateDuringUpdate(
                            //       index, state, setModalState);
                            // },
                            // textFieldConfiguration: TextFieldConfiguration(
                            //   onTap: () {},
                            //   //autofocus: true,
                            //   controller: _stateControllerListForUpdate[index],
                            //   onSubmitted: (txt) {
                            //     // _searchKey = txt;
                            //     // setState(() {});
                            //     // _onSearchSubmit();
                            //   },
                            //   decoration: buildAddressInputDecoration(
                            //       context,
                            //       AppLocalizations.of(context)!
                            //           .enter_state_ucf),
                            // ),
                            onSelected: (value) {},
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                            "${AppLocalizations.of(context)!.city_ucf} *",
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          height: 40,
                          child: TypeAheadField(
                            controller: _cityControllerListForUpdate[index],
                            suggestionsCallback: (name) async {
                              if (_selected_state_list_for_update[index] ==
                                  null) {
                                var cityResponse = await AddressRepository()
                                    .getCityListByState(); // blank response
                                return cityResponse.cities;
                              }
                              var cityResponse = await AddressRepository()
                                  .getCityListByState(
                                      state_id: _selected_state_list_for_update[
                                              index]!
                                          .id,
                                      name: name);
                              return cityResponse.cities;
                            },
                            loadingBuilder: (context) {
                              return Container(
                                height: 50,
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .loading_cities_ucf,
                                        style: TextStyle(
                                            color: MyTheme.medium_grey))),
                              );
                            },
                            itemBuilder: (context, dynamic city) {
                              //print(suggestion.toString());
                              return ListTile(
                                dense: true,
                                title: Text(
                                  city.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {},
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(AppLocalizations.of(context)!.phone_ucf,
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _phoneControllerListForUpdate[index],
                            autofocus: false,
                            decoration: buildAddressInputDecoration(
                                context,
                                AppLocalizations.of(context)!
                                    .enter_phone_number),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            side: BorderSide(
                                color: MyTheme.light_grey, width: 1.0)),
                        child: Text(
                          AppLocalizations.of(context)!.close_all_capital,
                          style: TextStyle(
                              color: MyTheme.accent_color, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 28.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.update_all_capital,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          onAddressUpdate(
                              context, index, _shippingAddressList[index].id);
                        },
                      ),
                    )
                  ],
                )
              ],
            );
          });
        });
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.dark_font_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.addresses_of_user,
            style: TextStyle(
                fontSize: 16,
                color: Color(0xff3E4447),
                fontWeight: FontWeight.bold),
          ),
          Text(
            "* ${AppLocalizations.of(context)!.double_tap_on_an_address_to_make_it_default}",
            style: TextStyle(fontSize: 12, color: Color(0xff6B7377)),
          ),
        ],
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildAddressList() {
    // print("is Initial: ${_isInitial}");
    if (is_logged_in == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else if (_isInitial && _shippingAddressList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildListShimmer(item_count: 5, item_height: 100.0));
    } else if (_shippingAddressList.length > 0) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(
              height: 16,
            );
          },
          itemCount: _shippingAddressList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildAddressItemCard(index);
          },
        ),
      );
    } else if (!_isInitial && _shippingAddressList.length == 0) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)!.no_address_is_added,
            style: TextStyle(color: MyTheme.font_grey),
          )));
    }
  }

  GestureDetector buildAddressItemCard(index) {
    return GestureDetector(
      onDoubleTap: () {
        if (_default_shipping_address != _shippingAddressList[index].id) {
          onAddressSwitch(_shippingAddressList[index].id);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        decoration: BoxDecorations.buildBoxDecoration_1().copyWith(
            border: Border.all(
                color:
                    _default_shipping_address == _shippingAddressList[index].id
                        ? MyTheme.accent_color
                        : MyTheme.light_grey,
                width:
                    _default_shipping_address == _shippingAddressList[index].id
                        ? 1.0
                        : 0.0)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 75,
                          child: Text(
                            AppLocalizations.of(context)!.address_ucf,
                            style: TextStyle(
                                color: const Color(0xff6B7377),
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        Container(
                          width: 175,
                          child: Text(
                            _shippingAddressList[index].address,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 75,
                          child: Text(
                            AppLocalizations.of(context)!.city_ucf,
                            style: TextStyle(
                                color: const Color(0xff6B7377),
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        Container(
                          width: 200,
                          child: Text(
                            _shippingAddressList[index].city_name,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 75,
                          child: Text(
                            AppLocalizations.of(context)!.state_ucf,
                            style: TextStyle(
                                color: const Color(0xff6B7377),
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        Container(
                          width: 200,
                          child: Text(
                            _shippingAddressList[index].state_name,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 75,
                          child: Text(
                            AppLocalizations.of(context)!.country_ucf,
                            style: TextStyle(
                                color: const Color(0xff6B7377),
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        Container(
                          width: 200,
                          child: Text(
                            _shippingAddressList[index].country_name,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 75,
                          child: Text(
                            AppLocalizations.of(context)!.phone_ucf,
                            style: TextStyle(
                                color: const Color(0xff6B7377),
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        Container(
                          width: 200,
                          child: Text(
                            _shippingAddressList[index].phone,
                            maxLines: 2,
                            style: TextStyle(
                                color: MyTheme.dark_grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            app_language_rtl.$!
                ? Positioned(
                    left: 0.0,
                    top: 10.0,
                    child: showOptions(listIndex: index),
                  )
                : Positioned(
                    right: 0.0,
                    top: 10.0,
                    child: showOptions(listIndex: index),
                  ),
            /*  app_language_rtl.$
                ? Positioned(
                    left: 0,
                    top: 40.0,
                    child: InkWell(
                      onTap: () {
                        onPressDelete(_shippingAddressList[index].id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 12.0, left: 16.0, right: 16.0, bottom: 16.0),
                        child: Icon(
                          Icons.delete_forever_outlined,
                          color: MyTheme.dark_grey,
                          size: 16,
                        ),
                      ),
                    ))
                : Positioned(
                    right: 0,
                    top: 40.0,
                    child: InkWell(
                      onTap: () {
                        onPressDelete(_shippingAddressList[index].id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 12.0, left: 16.0, right: 16.0, bottom: 16.0),
                        child: Icon(
                          Icons.delete_forever_outlined,
                          color: MyTheme.dark_grey,
                          size: 16,
                        ),
                      ),
                    )),
            OtherConfig.USE_GOOGLE_MAP
                ? Positioned(
                    right: 0,
                    top: 80.0,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return MapLocation(
                              address: _shippingAddressList[index]);
                        })).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 12.0, left: 16.0, right: 16.0, bottom: 16.0),
                        child: Icon(
                          Icons.location_on,
                          color: MyTheme.dark_grey,
                          size: 16,
                        ),
                      ),
                    ))
                : Container()*/
          ],
        ),
      ),
    );
  }

  buildBottomAppBar(BuildContext context) {
    return Visibility(
      visible: widget.from_shipping_info,
      child: BottomAppBar(
        color: Colors.transparent,
        child: Container(
          height: 50,
          child: Btn.minWidthFixHeight(
            minWidth: MediaQuery.of(context).size.width,
            height: 50,
            color: MyTheme.accent_color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.0),
            ),
            child: Text(
              AppLocalizations.of(context)!.back_to_shipping_info,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              return Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget showOptions({listIndex, productId}) {
    return Container(
      width: 45,
      child: PopupMenuButton<MenuOptions>(
        offset: Offset(-25, 0),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            width: 45,
            padding: EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.topRight,
            child: Image.asset("assets/more.png",
                width: 4,
                height: 16,
                fit: BoxFit.contain,
                color: MyTheme.grey_153),
          ),
        ),
        onSelected: (MenuOptions result) {
          _tabOption(result.index, listIndex);
          // setState(() {
          //   //_menuOptionSelected = result;
          // });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOptions>>[
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Edit,
            child: Text(AppLocalizations.of(context)!.edit_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Delete,
            child: Text(AppLocalizations.of(context)!.delete_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.AddLocation,
            child: Text(AppLocalizations.of(context)!.add_location_ucf),
          ),
        ],
      ),
    );
  }
}

enum MenuOptions { Edit, Delete, AddLocation }
