library csc_picker;

import 'dart:convert';

import 'package:csc_picker/dropdown_with_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'model/select_status_model.dart';

enum Layout { vertical, horizontal }
enum CountryFlag { SHOW_IN_DROP_DOWN_ONLY, ENABLE, DISABLE }

class CSCPicker extends StatefulWidget {
  final ValueChanged<Country?>? onCountryChanged;
  final ValueChanged<Region?>? onStateChanged;
  final ValueChanged<City?>? onCityChanged;

  ///Parameters to change style of CSC Picker
  final TextStyle? selectedItemStyle, dropdownHeadingStyle, dropdownItemStyle;
  final BoxDecoration? dropdownDecoration, disabledDropdownDecoration;
  final bool showStates, showCities;
  final CountryFlag flagState;
  final Layout layout;
  final double? searchBarRadius;
  final double? dropdownDialogRadius;

  ///init country
  final String? initCountryAbbr;

  ///init state abbr
  final String? initStateAbbr;

  ///init city name
  final String? initCity;

  ///CSC Picker Constructor
  const CSCPicker(
      {Key? key,
      this.onCountryChanged,
      this.onStateChanged,
      this.onCityChanged,
      this.selectedItemStyle,
      this.dropdownHeadingStyle,
      this.dropdownItemStyle,
      this.dropdownDecoration,
      this.disabledDropdownDecoration,
      this.searchBarRadius,
      this.dropdownDialogRadius,
      this.flagState = CountryFlag.ENABLE,
      this.layout = Layout.horizontal,
      this.showStates = true,
      this.showCities = true,
      this.initCountryAbbr,
      this.initStateAbbr,
      this.initCity})
      : super(key: key);

  @override
  _CSCPickerState createState() => _CSCPickerState();
}

class _CSCPickerState extends State<CSCPicker> {
  List<Country> _countryList = [];
  List<Region> _statesList = [];
  List<City> _citiesList = [];

  Country? _selectedCountry;
  Region? _selectedState;
  City? _selectedCity;

  var responses;

  @override
  void initState() {
    // TODO: implement initState
    getCounty();
    super.initState();
  }

  ///Read JSON country data from assets
  Future getResponse() async {
    final res = await rootBundle.loadString('packages/csc_picker/lib/assets/country.json');
    final countries = jsonDecode(res) as List;

    setState(() {
      countries.forEach((element) {
        _countryList.add(Country.fromJson(element as Map<String, dynamic>));
      });
    });
  }

  ///get countries from json response
  Future getCounty() async {
    _selectedCountry = null;
    await getResponse();

    //selected init country
    if (widget.initCountryAbbr != null) {
      _selectedCountry =
          _countryList.firstWhere((element) => element.abbr == widget.initCountryAbbr, orElse: () => null as Country);
      await getState();
    }

    //selected init state
    if (widget.initStateAbbr != null) {
      _selectedState = _selectedCountry?.state
          ?.firstWhere((element) => element.abbr == widget.initStateAbbr, orElse: () => null as Region);
      await getCity();
    }

    if (widget.initCity != null) {
      _selectedCity = City(name: widget.initCity);
    }
  }

  ///get states from json response
  Future getState() async {
    _statesList.clear();
    if (!mounted) return;

    //sort useless
    _selectedCountry?.state?.sort((a, b) => a.name!.compareTo(b.name!));
    _statesList = _selectedCountry?.state ?? [];
  }

  ///get cities from json response
  Future getCity() async {
    _citiesList.clear();
    if (!mounted) return;

    //sort useless
    _selectedState?.city?.sort((a, b) => a.name!.compareTo(b.name!));
    _citiesList = _selectedState?.city ?? [];
  }

  ///get methods to catch newly selected country state and city and populate state based on country, and city based on state
  void _onSelectedCountry(Country value) {
    if (!mounted) return;

    setState(() {
      if (this.widget.onCountryChanged != null) {
        this.widget.onCountryChanged!(value);
      }

      _statesList.clear();
      _citiesList.clear();
      _selectedCountry = value;
      _selectedState = null;
      _selectedCity = null;
      getState();
    });
  }

  void _onSelectedState(Region value) {
    if (!mounted) return;

    setState(() {
      if (this.widget.onStateChanged != null) {
        this.widget.onStateChanged!(value);
      }
      _citiesList.clear();
      _selectedState = value;
      _selectedCity = null;
      getCity();
    });
  }

  void _onSelectedCity(City value) {
    if (!mounted) return;
    setState(() {
      if (this.widget.onCityChanged != null) {
        this.widget.onCityChanged!(value);
      }
      _selectedCity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.layout == Layout.vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  countryDropdown(),
                  SizedBox(
                    height: 10.0,
                  ),
                  stateDropdown(),
                  SizedBox(
                    height: 10.0,
                  ),
                  cityDropdown()
                ],
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(child: countryDropdown()),
                      widget.showStates
                          ? SizedBox(
                              width: 10.0,
                            )
                          : Container(),
                      widget.showStates ? Expanded(child: stateDropdown()) : Container(),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  widget.showStates && widget.showCities ? cityDropdown() : Container()
                ],
              ),
      ],
    );
  }

  ///Country Dropdown Widget
  Widget countryDropdown() {
    return DropdownWithSearch(
      title: "Country",
      placeHolder: "Search Country",
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      disabledDecoration: widget.disabledDropdownDecoration,
      disabled: _countryList.length == 0 ? true : false,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      items: _countryList,
      selected: _selectedCountry?.name == null
          ? 'Country'
          : '${_selectedCountry?.emoji ?? ''} ${_selectedCountry?.name ?? ''}',
      onChanged: (value) => _onSelectedCountry(value),
    );
  }

  ///State Dropdown Widget
  Widget stateDropdown() {
    return DropdownWithSearch(
      title: "State",
      placeHolder: "Search State",
      disabled: _statesList.length == 0 ? true : false,
      items: _statesList,
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      disabledDecoration: widget.disabledDropdownDecoration,
      selected: _selectedState?.name ?? 'State',
      onChanged: (value) => _onSelectedState(value),
    );
  }

  ///City Dropdown Widget
  Widget cityDropdown() {
    return DropdownWithSearch(
      title: "City",
      placeHolder: "Search City",
      disabled: _citiesList.length == 0 ? true : false,
      items: _citiesList,
      selectedItemStyle: widget.selectedItemStyle,
      dropdownHeadingStyle: widget.dropdownHeadingStyle,
      itemStyle: widget.dropdownItemStyle,
      decoration: widget.dropdownDecoration,
      dialogRadius: widget.dropdownDialogRadius,
      searchBarRadius: widget.searchBarRadius,
      disabledDecoration: widget.disabledDropdownDecoration,
      selected: _selectedCity?.name ?? 'City',
      onChanged: (value) => _onSelectedCity(value),
    );
  }
}
