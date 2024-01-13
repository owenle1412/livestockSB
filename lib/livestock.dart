import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import './item.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class LiveStock extends StatefulWidget {
  const LiveStock({super.key});

  @override
  State<LiveStock> createState() => _LiveStockState();
}

class _LiveStockState extends State<LiveStock> {
  late bool isLoading;
  late bool isSearchLoading;
  List<String> storeList = [];
  List<String> itemgroupList = [];
  List<Item> itemList = [];
  List<Item> filteredItemList = [];
  String errorInitMessage = '';
  String searchMessage = '';
  String? selectedStore = '';
  String? selectedItemGroup = '';
  late bool isFilterScanEnabled;
  var barcodeTxtField = TextEditingController();
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    getDropdownsValue();
    
    isSearchLoading = false;
    isFilterScanEnabled = false;
    scrollController = ScrollController()
      ..addListener(() {
        FocusScope.of(context).requestFocus(FocusNode());
      });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Starsbuck Live Stock"),
        ),
        body: !isLoading
            ? (errorInitMessage != '')
                ? Center(
                    child: SizedBox(
                      child: Text(errorInitMessage),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                          width: double.infinity,
                          color: Theme.of(context).primaryColor,
                          child: _buildForm(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: barcodeTxtField,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Input barcode',
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(12)),
                                style: const TextStyle(fontSize: 14),
                                enabled: isFilterScanEnabled ? true : false,
                                onChanged: searchBarcode,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            SizedBox(
                              width: 100,
                              height: 43,
                              child: ElevatedButton(
                                onPressed:
                                    isFilterScanEnabled ? scanBarcode : null,
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          isFilterScanEnabled
                                              ? Colors.red
                                              : Colors.grey),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                ),
                                child: const Text('Scan'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      !isSearchLoading
                          ? (searchMessage != '')
                              ? Column(children: [
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Text(searchMessage),
                                  ),
                                ])
                              : Expanded(child: _buildStockDisplay(context))
                          : const Column(children: [
                              SizedBox(height: 20),
                              Center(
                                child: SizedBox(
                                  height: 50.0,
                                  width: 50.0,
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ])
                    ],
                  )
            : const Center(
                child: SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: CircularProgressIndicator(),
                ),
              ));
  }

  Future<Response> getStoreCodeList() async {
    Uri url = Uri.https('w7v49.wiremockapi.cloud', '/storecode');
    // await Future.delayed(const Duration(seconds: 3));
    return http.get(url);
  }

  Future<Response> getItemGroupList() async {
    Uri url = Uri.https('w7v49.wiremockapi.cloud', '/itemgroup');
    // await Future.delayed(const Duration(seconds: 3));
    return http.get(url);
  }

  Future<Response> getItemsFromAPI() async {
    // print('$selectedStore - $selectedItemGroup');
    Uri url = Uri.https('w7v49.wiremockapi.cloud', '/storestock');
    // await Future.delayed(const Duration(seconds: 3));
    return http.get(url);
  }

  void getSearchResult() async {
    setState(() {
      searchMessage = "";
      isSearchLoading = true;
      isFilterScanEnabled = false;
      barcodeTxtField.text = "";
    });

    List<Item> items = [];

    try {
      Response itemsValue = await getItemsFromAPI();
      if (itemsValue.statusCode == HttpStatus.ok) {
        final jsonResponse = json.decode(itemsValue.body);
        items = jsonResponse.map<Item>((i) => Item.fromJson(i)).toList();
      }
      setState(() {
        itemList = items;
        filteredItemList = items;
        if (itemList.isNotEmpty) {
          isFilterScanEnabled = true;
        }
        isSearchLoading = false;
      });
    } catch (error) {
      setState(() {
        if (error.toString().contains("Failed host lookup")) {
          searchMessage = "Check Internet Connection";
        }
        else {
          searchMessage = error.toString();
        }     
        isSearchLoading = false;
      });
    }
  }

  void getDropdownsValue() async {
    isLoading = true;
    List<String> stores = [];
    List<String> itemgroup = [];

    try {
      Response storeValue = await getStoreCodeList();
      Response itemGroupValue = await getItemGroupList();

      if (storeValue.statusCode == HttpStatus.ok) {
        Map<String, dynamic> storeMap = json.decode(storeValue.body);
        stores = List<String>.from(storeMap['stores']);
      }
      if (itemGroupValue.statusCode == HttpStatus.ok) {
        Map<String, dynamic> itemGroupMap = json.decode(itemGroupValue.body);
        itemgroup = List<String>.from(itemGroupMap['itemgroup']);
      }

      setState(() {
        storeList = stores;
        itemgroupList = itemgroup;
        isLoading = false;
        selectedStore = storeList.isNotEmpty ? storeList.first : '';
        selectedItemGroup = itemgroupList.isNotEmpty ? itemgroupList.first : '';
        
      });
    } catch (error) {
      setState(() {
        if (error.toString().contains("Failed host lookup")) {
          errorInitMessage = "Check Internet Connection";
        }
        else {
          errorInitMessage = error.toString();
        }       
        isLoading = false;
      });
    }
  }

  Widget _buildStockDisplay(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      itemCount: filteredItemList.length,
      itemBuilder: (context, index) {
        int maxLen = filteredItemList[index].description.length;
        String moreDot = "";
        if (maxLen > 28) {
          maxLen = 28;
          moreDot = "...";
        }
        return ListTile(
          title:  Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
            '${filteredItemList[index].barCode} (${filteredItemList[index].itemCode})',
            style: const TextStyle(fontSize: 15),
          ),
          ),
          subtitle: Text(filteredItemList[index].description.substring(0,
            maxLen) + moreDot),
          trailing: Text('Qty: ${filteredItemList[index].qty}'),
        );
      },
      separatorBuilder: (context,index){
        return const Divider(
          thickness: 2,
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: DropdownSearch<String>(
            popupProps: const PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                fit: FlexFit.loose),
            items: storeList,
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                  labelText: "Store code",
                  filled: true,
                  fillColor: Colors.white),
            ),
            onChanged: (String? value) {
              selectedStore = value;
            },
            selectedItem: (storeList.isEmpty) ? "" : storeList.first,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: DropdownSearch<String>(
            popupProps: const PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                fit: FlexFit.loose),
            items: itemgroupList,
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                  labelText: "Item group",
                  filled: true,
                  fillColor: Colors.white),
            ),
            onChanged: (String? value) {
              selectedItemGroup = value;
            },
            selectedItem: (itemgroupList.isEmpty) ? "" : itemgroupList.first,
            // asyncItems: (f) => getData(f)
          ),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
          onPressed: () {
            getSearchResult();
          },
          child: const Text('Search'),
        ),
        const SizedBox(height: 10)
      ],
    );
  }

  void searchBarcode(String value) {
    final suggestions = itemList.where((item) {
      return item.barCode.startsWith(value);
    }).toList();

    setState(() {
      filteredItemList = suggestions;
    });
  }

  Future scanBarcode() async {
    String scanResult;

    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
          "#6200EE", "Cancel", false, ScanMode.BARCODE);
    } on PlatformException {
      scanResult = "Failed to get platform version";
    } catch (error) {
      scanResult = error.toString();
    }

    if (scanResult == '-1') {
      scanResult = "";
    }

    if (!mounted) return;

    setState(() {
      barcodeTxtField.text = scanResult;
      searchBarcode(scanResult);
    });
  }
}
