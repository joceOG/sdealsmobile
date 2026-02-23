import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../../data/services/api_client.dart';

// Events
abstract class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends EditProfileEvent {
  final String userId;
  const LoadUserProfile(this.userId);
}

class UpdateProfile extends EditProfileEvent {
  final String userId;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String? genre;
  final String? datedenaissance;
  final File? photoProfil;
  final String token;

  const UpdateProfile({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    this.genre,
    this.datedenaissance,
    this.photoProfil,
    required this.token,
  });

  @override
  List<Object?> get props => [
        userId,
        nom,
        prenom,
        telephone,
        email,
        genre,
        datedenaissance,
        photoProfil,
        token,
      ];
}

class ClearEditProfile extends EditProfileEvent {}

// States
abstract class EditProfileState extends Equatable {
  const EditProfileState();

  @override
  List<Object?> get props => [];
}

class EditProfileInitial extends EditProfileState {}

class EditProfileLoading extends EditProfileState {}

class EditProfileLoaded extends EditProfileState {
  final Map<String, dynamic> userData;

  const EditProfileLoaded(this.userData);

  @override
  List<Object?> get props => [userData];
}

class EditProfileSuccess extends EditProfileState {
  final String message;
  final Map<String, dynamic> updatedUser;

  const EditProfileSuccess(this.message, this.updatedUser);

  @override
  List<Object?> get props => [message, updatedUser];
}

class EditProfileError extends EditProfileState {
  final String error;

  const EditProfileError(this.error);

  @override
  List<Object?> get props => [error];
}

// BLoC
class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final ApiClient _apiClient;

  EditProfileBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(EditProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ClearEditProfile>(_onClearEditProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(EditProfileLoading());
    try {
      // Charger les données utilisateur
      final userData = await _apiClient.getUserById(event.userId);
      emit(EditProfileLoaded(userData));
    } catch (e) {
      emit(EditProfileError('Erreur lors du chargement du profil: $e'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(EditProfileLoading());
    try {
      // Préparer les données à envoyer
      final Map<String, dynamic> updateData = {
        'nom': event.nom,
        'prenom': event.prenom,
        'telephone': event.telephone,
        'email': event.email,
      };

      if (event.genre != null) updateData['genre'] = event.genre;
      if (event.datedenaissance != null)
        updateData['datedenaissance'] = event.datedenaissance;

      // Appel API pour mettre à jour le profil
      final updatedUser = await _apiClient.updateUserProfile(
        userId: event.userId,
        updateData: updateData,
        photoFile: event.photoProfil,
        token: event.token,
      );

      emit(EditProfileSuccess('Profil mis à jour avec succès', updatedUser));
    } catch (e) {
      emit(EditProfileError('Erreur lors de la mise à jour: $e'));
    }
  }

  void _onClearEditProfile(
    ClearEditProfile event,
    Emitter<EditProfileState> emit,
  ) {
    emit(EditProfileInitial());
  }
}










