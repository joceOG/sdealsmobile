import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageEventM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageStateM.dart';

import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';

class HomePageBlocM extends Bloc<HomePageEventM, HomePageStateM> {
  HomePageBlocM() : super(HomePageStateM.initial()) {
    on<LoadCategorieDataM>(_onLoadCategorieDataM);
  }

  Future<void> _onLoadCategorieDataM(
    LoadCategorieDataM event,
    Emitter<HomePageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: ''));

    final apiClient = ApiClient();
    try {
      const nomgroupe = 'Métiers';
      final List<Categorie> listCategorie =
          await apiClient.fetchCategorie(nomgroupe);
      emit(state.copyWith(
        listItems: listCategorie,
        isLoading: false,
        error: '',
      ));
    } catch (error) {
      emit(state.copyWith(
        error: userFacingNetworkMessage(error),
        isLoading: false,
      ));
    }
  }
}
