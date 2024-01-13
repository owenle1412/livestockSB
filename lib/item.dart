class Item {
  final String itemCode;
  final String barCode;
  final String description;
  final num qty;

  Item.fromJson(Map<String,dynamic> json):
    itemCode = json['itemCode'],
    barCode = json['barCode'],
    description = json['description'],
    qty = json['qty'];
}