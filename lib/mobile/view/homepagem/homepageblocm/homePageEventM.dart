import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

abstract class HomePageEventM extends Equatable {
  const HomePageEventM();

  @override
  List<Object> get props => [];
}

class LoadCategorieDataM extends HomePageEventM {}
