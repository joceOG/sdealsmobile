import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

class HomePageStateM extends Equatable {
  final bool isLoading;
  final List<Categorie>? listItems;
  final String? error;
  final bool showingSaved;

  const HomePageStateM({
    this.isLoading = true,
    this.listItems,
    this.error = '',
    this.showingSaved = false,
  });

  factory HomePageStateM.initial() {
    return const HomePageStateM(
      isLoading: true,
      listItems: null,
      error: '',
    );
  }

  HomePageStateM copyWith({
    bool? isLoading,
    List<Categorie>? listItems,
    String? error,
    bool? showingSaved,
  }) {
    return HomePageStateM(
      isLoading: isLoading ?? this.isLoading,
      listItems: listItems ?? this.listItems,
      error: error ?? this.error,
      showingSaved: showingSaved ?? this.showingSaved,
    );
  }

  @override
  List<Object?> get props => [isLoading, listItems, error, showingSaved];
}
