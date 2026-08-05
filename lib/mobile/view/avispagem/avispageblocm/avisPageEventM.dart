import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/avis.dart';

abstract class AvisPageEventM extends Equatable {
  const AvisPageEventM();

  @override
  List<Object?> get props => [];
}

// 📋 CHARGEMENT DES AVIS
class LoadAvisDataM extends AvisPageEventM {
  final String? objetType;
  final String? objetId;
  final String? statut;
  final int? note;
  final String? searchTerm;

  const LoadAvisDataM({
    this.objetType,
    this.objetId,
    this.statut,
    this.note,
    this.searchTerm,
  });

  @override
  List<Object?> get props => [objetType, objetId, statut, note, searchTerm];
}

// 🔍 RECHERCHE D'AVIS
class SearchAvisM extends AvisPageEventM {
  final String query;
  final String? objetType;
  final String? ville;

  const SearchAvisM({
    required this.query,
    this.objetType,
    this.ville,
  });

  @override
  List<Object?> get props => [query, objetType, ville];
}

// 📝 CRÉATION D'AVIS (seule la note est obligatoire)
class CreateAvisM extends AvisPageEventM {
  final String objetType;
  final String objetId;
  final int note;
  final String? titre;
  final String? commentaire;
  final List<CategorieEvaluation>? categories;
  final List<MediaAvis>? medias;
  final bool recommande;
  final LocalisationAvis? localisation;
  final List<String>? tags;
  final bool anonyme;

  const CreateAvisM({
    required this.objetType,
    required this.objetId,
    required this.note,
    this.titre,
    this.commentaire,
    this.categories,
    this.medias,
    this.recommande = true,
    this.localisation,
    this.tags,
    this.anonyme = false,
  });

  @override
  List<Object?> get props => [
        objetType,
        objetId,
        note,
        titre,
        commentaire,
        categories,
        medias,
        recommande,
        localisation,
        tags,
        anonyme,
      ];
}

// ✏️ MODIFICATION D'AVIS
class UpdateAvisM extends AvisPageEventM {
  final String avisId;
  final String? titre;
  final String? commentaire;
  final int? note;
  final List<CategorieEvaluation>? categories;
  final bool? recommande;
  final List<String>? tags;

  const UpdateAvisM({
    required this.avisId,
    this.titre,
    this.commentaire,
    this.note,
    this.categories,
    this.recommande,
    this.tags,
  });

  @override
  List<Object?> get props => [
        avisId,
        titre,
        commentaire,
        note,
        categories,
        recommande,
        tags,
      ];
}

// 🗑️ SUPPRESSION D'AVIS
class DeleteAvisM extends AvisPageEventM {
  final String avisId;

  const DeleteAvisM({required this.avisId});

  @override
  List<Object> get props => [avisId];
}

// 👍 MARQUER COMME UTILE
class MarquerUtileM extends AvisPageEventM {
  final String avisId;
  final bool utile; // true pour utile, false pour pas utile

  const MarquerUtileM({
    required this.avisId,
    required this.utile,
  });

  @override
  List<Object> get props => [avisId, utile];
}

// 💬 RÉPONDRE À UN AVIS
class RepondreAvisM extends AvisPageEventM {
  final String avisId;
  final String contenu;

  const RepondreAvisM({
    required this.avisId,
    required this.contenu,
  });

  @override
  List<Object> get props => [avisId, contenu];
}

// 🚨 SIGNALER UN AVIS
class SignalerAvisM extends AvisPageEventM {
  final String avisId;
  final List<String> motifs;

  const SignalerAvisM({
    required this.avisId,
    required this.motifs,
  });

  @override
  List<Object> get props => [avisId, motifs];
}

// 📊 STATISTIQUES D'UN OBJET
class LoadStatsObjetM extends AvisPageEventM {
  final String objetType;
  final String objetId;

  const LoadStatsObjetM({
    required this.objetType,
    required this.objetId,
  });

  @override
  List<Object> get props => [objetType, objetId];
}

// 🔄 ACTUALISATION
class RefreshAvisM extends AvisPageEventM {
  const RefreshAvisM();
}

// 📱 AVIS RÉCENTS
class LoadAvisRecentsM extends AvisPageEventM {
  final int limit;

  const LoadAvisRecentsM({this.limit = 10});

  @override
  List<Object> get props => [limit];
}

// 🏷️ FILTRER PAR TAGS
class FilterByTagsM extends AvisPageEventM {
  final List<String> tags;

  const FilterByTagsM({required this.tags});

  @override
  List<Object> get props => [tags];
}

// 📍 FILTRER PAR LOCALISATION
class FilterByLocationM extends AvisPageEventM {
  final String ville;
  final String? pays;

  const FilterByLocationM({
    required this.ville,
    this.pays,
  });

  @override
  List<Object?> get props => [ville, pays];
}
