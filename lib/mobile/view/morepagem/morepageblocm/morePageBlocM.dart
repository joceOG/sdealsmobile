import 'package:sdealsmobile/mobile/view/morepagem/morepageblocm/morePageEventM.dart';
import 'package:sdealsmobile/mobile/view/morepagem/morepageblocm/morePageStateM.dart';

import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';



class MorePageBlocM extends Bloc<MorePageEventM, MorePageStateM> {

  MorePageBlocM() : super( MorePageStateM.initial()) {
    on<LoadCategorieDataM>(_onLoadCategorieDataM);
  }

  Future<void> _onLoadCategorieDataM(LoadCategorieDataM event,
      Emitter<MorePageStateM> emit,) async {
    // String nomgroupe = "Metiers";
    // emit(state.copyWith3(isLoading2: true));
    emit(state.copyWith(isLoading: true));

    ApiClient apiClient = ApiClient();
    print("Try");
    try {
      var nomgroupe = "Métiers" ;
      List<Categorie> list_categorie = await apiClient.fetchCategorie(nomgroupe);
      print("List Categorie");
      emit(state.copyWith(listItems: list_categorie, isLoading: false));
    } catch (error) {
      //   emit(state.copyWith3(error2: error.toString(), isLoading2: false));
      emit(state.copyWith(error: error.toString(), isLoading: false));
    }
  }

}
