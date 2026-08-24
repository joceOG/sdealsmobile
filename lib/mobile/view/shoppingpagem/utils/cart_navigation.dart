import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/panierProductScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';

/// STAB-12C — ouvre le panier en capturant le BLoC *avant* le push
/// (évite ProviderNotFound quand le builder ombre le context).
void openShoppingCart(BuildContext context) {
  final bloc = context.read<ShoppingPageBlocM>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const PanierProductScreenM(),
      ),
    ),
  );
}

/// True si l'ID Mongo ressemble à un ObjectId valide (24 hex).
bool isLikelyMongoObjectId(String? id) {
  if (id == null) return false;
  final s = id.trim();
  if (s.length != 24) return false;
  return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(s);
}
