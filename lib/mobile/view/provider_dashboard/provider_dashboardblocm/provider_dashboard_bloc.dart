import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/ai_services/interfaces/demand_prediction_service.dart';
import 'package:sdealsmobile/ai_services/mock_implementations/mock_demand_prediction_service.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/provider_dashboardblocm/provider_dashboard_event.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/provider_dashboardblocm/provider_dashboard_state.dart';

class ProviderDashboardBloc extends Bloc<ProviderDashboardEvent, ProviderDashboardState> {
  final DemandPredictionService _demandService = MockDemandPredictionService();
  
  ProviderDashboardBloc() : super(ProviderDashboardInitialState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboard);
    on<GetDemandPredictionEvent>(_onGetDemandPrediction);
    on<GetTopTrendingCategoriesEvent>(_onGetTopTrendingCategories);
    on<GetProviderInsightsEvent>(_onGetProviderInsights);
    on<GetHistoricalDataEvent>(_onGetHistoricalData);
  }

  void _onLoadDashboard(LoadDashboardDataEvent event, Emitter<ProviderDashboardState> emit) async {
    emit(ProviderDashboardLoadingState());
    // Plus de données inventées (« Kouassi Services », 57 jobs…) présentées comme réelles.
    emit(ProviderDashboardErrorState(
      message:
          'Tableau de bord : données live non branchées. Utilisez Planning et Missions.',
    ));
  }

  void _onGetDemandPrediction(GetDemandPredictionEvent event, Emitter<ProviderDashboardState> emit) async {
    if (state is ProviderDashboardLoadedState) {
      final currentState = state as ProviderDashboardLoadedState;
      
      emit(ProviderDashboardUpdatingState(
        providerData: currentState.providerData,
        providerCategories: currentState.providerCategories,
        location: currentState.location,
      ));
      
      try {
        final prediction = await _demandService.predictDemand(
          categorie: event.categorie,
          location: event.location,
          daysAhead: event.daysAhead,
        );
        
        emit(ProviderDashboardDemandPredictionLoadedState(
          providerData: currentState.providerData,
          providerCategories: currentState.providerCategories,
          location: currentState.location,
          prediction: prediction,
        ));
      } catch (e) {
        emit(ProviderDashboardErrorState(message: 'Erreur lors de la prédiction: ${e.toString()}'));
      }
    }
  }

  void _onGetTopTrendingCategories(GetTopTrendingCategoriesEvent event, Emitter<ProviderDashboardState> emit) async {
    if (state is ProviderDashboardLoadedState) {
      final currentState = state as ProviderDashboardLoadedState;
      
      emit(ProviderDashboardUpdatingState(
        providerData: currentState.providerData,
        providerCategories: currentState.providerCategories,
        location: currentState.location,
      ));
      
      try {
        final trendingCategories = await _demandService.getTopTrendingCategories(
          location: event.location,
          limit: event.limit,
        );
        
        emit(ProviderDashboardTrendsLoadedState(
          providerData: currentState.providerData,
          providerCategories: currentState.providerCategories,
          location: currentState.location,
          trendingCategories: trendingCategories,
        ));
      } catch (e) {
        emit(ProviderDashboardErrorState(message: 'Erreur lors du chargement des tendances: ${e.toString()}'));
      }
    }
  }

  void _onGetProviderInsights(GetProviderInsightsEvent event, Emitter<ProviderDashboardState> emit) async {
    if (state is ProviderDashboardLoadedState) {
      final currentState = state as ProviderDashboardLoadedState;
      
      emit(ProviderDashboardUpdatingState(
        providerData: currentState.providerData,
        providerCategories: currentState.providerCategories,
        location: currentState.location,
      ));
      
      try {
        final insights = await _demandService.generateProviderInsights(
          providerData: currentState.providerData,
          providerCategories: currentState.providerCategories,
          location: currentState.location,
        );
        
        emit(ProviderDashboardInsightsLoadedState(
          providerData: currentState.providerData,
          providerCategories: currentState.providerCategories,
          location: currentState.location,
          insights: insights,
        ));
      } catch (e) {
        emit(ProviderDashboardErrorState(message: 'Erreur lors du chargement des insights: ${e.toString()}'));
      }
    }
  }

  void _onGetHistoricalData(GetHistoricalDataEvent event, Emitter<ProviderDashboardState> emit) async {
    if (state is ProviderDashboardLoadedState) {
      final currentState = state as ProviderDashboardLoadedState;
      
      emit(ProviderDashboardUpdatingState(
        providerData: currentState.providerData,
        providerCategories: currentState.providerCategories,
        location: currentState.location,
      ));
      
      try {
        final historicalData = await _demandService.getHistoricalDemandData(
          categorie: event.categorie,
          location: event.location,
          periodInDays: event.periodInDays,
        );
        
        emit(ProviderDashboardHistoricalDataLoadedState(
          providerData: currentState.providerData,
          providerCategories: currentState.providerCategories,
          location: currentState.location,
          historicalData: historicalData,
          categorie: event.categorie,
        ));
      } catch (e) {
        emit(ProviderDashboardErrorState(message: 'Erreur lors du chargement des données historiques: ${e.toString()}'));
      }
    }
  }
}
