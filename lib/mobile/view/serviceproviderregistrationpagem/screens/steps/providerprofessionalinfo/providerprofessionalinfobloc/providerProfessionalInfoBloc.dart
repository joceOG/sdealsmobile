import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

import 'providerProfessionalInfoState.dart';
import 'providerProfessionalInfoEvent.dart';

class ProviderProfessionalInfoBloc extends Bloc<ProviderProfessionalInfoEvent, ProviderProfessionalInfoState> {
  ProviderProfessionalInfoBloc() : super(ProviderProfessionalInfoState.initial()) {
    on<LoadCategorieData>(_onLoadCategorieData);
    on<LoadServiceData>(_onLoadServiceData);
  }

  Future<void> _onLoadCategorieData(
      LoadCategorieData event,
      Emitter<ProviderProfessionalInfoState> emit,
      ) async {
    emit(state.copyWith(isLoading: true));

    try {
      var nomgroupe = "Métiers";
      List<Categorie> listCategorie = await ApiClient().fetchCategorie(nomgroupe);

      emit(state.copyWith(
        listItems: listCategorie,
        isLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(error: error.toString(), isLoading: false));
    }
  }

  Future<void> _onLoadServiceData(
      LoadServiceData event,
      Emitter<ProviderProfessionalInfoState> emit,
      ) async {
    emit(state.copyWith(isLoading2: true));
    var nomgroupe = "Métiers";
    try {
      List<Service> listService = await ApiClient().fetchServices(nomgroupe);

      emit(state.copyWith(
        listItems2: listService,
        isLoading2: false,
      ));
    } catch (error) {
      emit(state.copyWith(error2: error.toString(), isLoading2: false));
    }
  }
}
