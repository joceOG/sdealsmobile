import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';


abstract class OrderPageEventM extends Equatable {
  const OrderPageEventM();

  @override
  List<Object> get props => [];
}

class LoadCategorieDataM extends OrderPageEventM {}


