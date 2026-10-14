import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'dart:convert';
import 'dart:io';

// 🎯 ÉVÉNEMENTS
abstract class PrestataireFinalizationEvent extends Equatable {
  const PrestataireFinalizationEvent();

  @override
  List<Object?> get props => [];
}

class SubmitFinalizationEvent extends PrestataireFinalizationEvent {
  final Map<String, dynamic> formData;

  const SubmitFinalizationEvent({required this.formData});

  @override
  List<Object?> get props => [formData];
}

class LoadDossierEvent extends PrestataireFinalizationEvent {
  final String prestataireId;
  final String authToken;

  const LoadDossierEvent({
    required this.prestataireId,
    required this.authToken,
  });

  @override
  List<Object?> get props => [prestataireId, authToken];
}

class UploadDocumentEvent extends PrestataireFinalizationEvent {
  final String documentType;
  final File file;
  final String prestataireId;
  final String authToken;

  const UploadDocumentEvent({
    required this.documentType,
    required this.file,
    required this.prestataireId,
    required this.authToken,
  });

  @override
  List<Object?> get props => [documentType, file, prestataireId, authToken];
}

class FinalizeDossierEvent extends PrestataireFinalizationEvent {
  final String prestataireId;
  final String authToken;
  final Map<String, dynamic>? locationMaps;
  final String? locationLabel;

  const FinalizeDossierEvent({
    required this.prestataireId,
    required this.authToken,
    this.locationMaps,
    this.locationLabel,
  });

  @override
  List<Object?> get props =>
      [prestataireId, authToken, locationMaps, locationLabel];
}

// 🎯 ÉTATS
abstract class PrestataireFinalizationState extends Equatable {
  const PrestataireFinalizationState();

  @override
  List<Object?> get props => [];
}

class PrestataireFinalizationInitial extends PrestataireFinalizationState {}

class PrestataireFinalizationLoading extends PrestataireFinalizationState {}

class PrestataireFinalizationSuccess extends PrestataireFinalizationState {
  final String message;

  const PrestataireFinalizationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PrestataireFinalizationFailure extends PrestataireFinalizationState {
  final String error;

  const PrestataireFinalizationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class DocumentUploadSuccess extends PrestataireFinalizationState {
  final String documentType;
  final String url;

  const DocumentUploadSuccess({
    required this.documentType,
    required this.url,
  });

  @override
  List<Object?> get props => [documentType, url];
}

class DocumentUploadFailure extends PrestataireFinalizationState {
  final String documentType;
  final String error;

  const DocumentUploadFailure({
    required this.documentType,
    required this.error,
  });

  @override
  List<Object?> get props => [documentType, error];
}

/// État du dossier (aucune URL KYC exposée dans l’UI).
class DossierLoaded extends PrestataireFinalizationState {
  const DossierLoaded({
    required this.hasCniRecto,
    required this.hasCniVerso,
    required this.hasSelfie,
    required this.hasDossierLocation,
    required this.locationLabel,
    required this.canFinalize,
    required this.canGetBadge,
    required this.prestataireStatus,
    this.uploadingFields = const {},
    this.pendingLocalFiles = const {},
  });

  final bool hasCniRecto;
  final bool hasCniVerso;
  final bool hasSelfie;
  final bool hasDossierLocation;
  final String locationLabel;
  final bool canFinalize;
  final bool canGetBadge;
  final String prestataireStatus;
  final Set<String> uploadingFields;
  final Map<String, String> pendingLocalFiles;

  DossierLoaded copyWith({
    bool? hasCniRecto,
    bool? hasCniVerso,
    bool? hasSelfie,
    bool? hasDossierLocation,
    String? locationLabel,
    bool? canFinalize,
    bool? canGetBadge,
    String? prestataireStatus,
    Set<String>? uploadingFields,
    Map<String, String>? pendingLocalFiles,
  }) {
    return DossierLoaded(
      hasCniRecto: hasCniRecto ?? this.hasCniRecto,
      hasCniVerso: hasCniVerso ?? this.hasCniVerso,
      hasSelfie: hasSelfie ?? this.hasSelfie,
      hasDossierLocation: hasDossierLocation ?? this.hasDossierLocation,
      locationLabel: locationLabel ?? this.locationLabel,
      canFinalize: canFinalize ?? this.canFinalize,
      canGetBadge: canGetBadge ?? this.canGetBadge,
      prestataireStatus: prestataireStatus ?? this.prestataireStatus,
      uploadingFields: uploadingFields ?? this.uploadingFields,
      pendingLocalFiles: pendingLocalFiles ?? this.pendingLocalFiles,
    );
  }

  @override
  List<Object?> get props => [
        hasCniRecto,
        hasCniVerso,
        hasSelfie,
        hasDossierLocation,
        locationLabel,
        canFinalize,
        canGetBadge,
        prestataireStatus,
        uploadingFields,
        pendingLocalFiles,
      ];
}

// 🎯 BLOC
class PrestataireFinalizationBloc
    extends Bloc<PrestataireFinalizationEvent, PrestataireFinalizationState> {
  final String apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';

  DossierLoaded? _lastDossier;

  PrestataireFinalizationBloc() : super(PrestataireFinalizationInitial()) {
    on<SubmitFinalizationEvent>(_onSubmitFinalization);
    on<LoadDossierEvent>(_onLoadDossier);
    on<UploadDocumentEvent>(_onUploadDocument);
    on<FinalizeDossierEvent>(_onFinalizeDossier);
  }

  Future<void> _onLoadDossier(
    LoadDossierEvent event,
    Emitter<PrestataireFinalizationState> emit,
  ) async {
    emit(PrestataireFinalizationLoading());
    try {
      final dossier = await _fetchDossier(
        event.prestataireId,
        event.authToken,
        pendingLocal: _lastDossier?.pendingLocalFiles ?? {},
        uploading: const {},
      );
      _lastDossier = dossier;
      emit(dossier);
    } catch (e) {
      emit(PrestataireFinalizationFailure(
          error: 'Impossible de charger le dossier: $e'));
    }
  }

  Future<DossierLoaded> _fetchDossier(
    String prestataireId,
    String authToken, {
    Map<String, String> pendingLocal = const {},
    Set<String> uploading = const {},
  }) async {
    final api = ApiClient();
    final statusRes = await api.get(
      '/prestataire/$prestataireId/finalization-status',
      token: authToken,
    );
    final docsRes = await api.get(
      '/prestataire/$prestataireId/documents',
      token: authToken,
    );

    bool hasCni1 = false;
    bool hasCni2 = false;
    bool hasSelfie = false;
    String locationLabel = '';
    String prestataireStatus = '';

    if (docsRes.statusCode == 200) {
      final data = ApiClient.decodeJson(docsRes);
      if (data is Map) {
        final docs = data['prestataire'] is Map
            ? (data['prestataire'] as Map)['documents']
            : data['documents'];
        if (docs is Map) {
          hasCni1 = _docPresent(docs['cni1']);
          hasCni2 = _docPresent(docs['cni2']);
          hasSelfie = _docPresent(docs['selfie']);
        }
        final p = data['prestataire'];
        if (p is Map && p['status'] != null) {
          prestataireStatus = p['status'].toString();
        }
      }
    }

    bool hasLocation = false;
    bool canGetBadge = false;

    if (statusRes.statusCode == 200) {
      final data = ApiClient.decodeJson(statusRes);
      if (data is Map) {
        final fs = data['finalizationStatus'];
        if (fs is Map) {
          canGetBadge = fs['canGetBadge'] == true;
          final req = fs['requiredDocs'];
          if (req is Map) {
            hasLocation = req['location'] == true;
          }
        }
        if (data['status'] != null) {
          prestataireStatus = data['status'].toString();
        }
      }
    }

    final profileRes = await api.get(
      '/prestataire/$prestataireId',
      token: authToken,
    );
    if (profileRes.statusCode == 200) {
      final profile = ApiClient.decodeJson(profileRes);
      if (profile is Map) {
        final loc = profile['localisation']?.toString().trim() ?? '';
        if (loc.isNotEmpty) locationLabel = loc;
        final maps = profile['localisationmaps'];
        if (maps is Map &&
            maps['latitude'] != null &&
            maps['longitude'] != null) {
          hasLocation = true;
          if (locationLabel.isEmpty) {
            locationLabel =
                'Lat ${maps['latitude']}, Lng ${maps['longitude']}';
          }
        }
        if (!hasCni1) hasCni1 = _docPresent(profile['cni1']);
        if (!hasCni2) hasCni2 = _docPresent(profile['cni2']);
        if (!hasSelfie) hasSelfie = _docPresent(profile['selfie']);
        if (profile['status'] != null) {
          prestataireStatus = profile['status'].toString();
        }
      }
    }

    return DossierLoaded(
      hasCniRecto: hasCni1,
      hasCniVerso: hasCni2,
      hasSelfie: hasSelfie,
      hasDossierLocation: hasLocation,
      locationLabel: locationLabel,
      canFinalize: hasLocation,
      canGetBadge: canGetBadge,
      prestataireStatus: prestataireStatus,
      pendingLocalFiles: pendingLocal,
      uploadingFields: uploading,
    );
  }

  bool _docPresent(dynamic value) {
    if (value == null) return false;
    final s = value.toString().trim();
    return s.isNotEmpty;
  }

  // 🎯 SOUMISSION DE LA FINALISATION
  Future<void> _onSubmitFinalization(
    SubmitFinalizationEvent event,
    Emitter<PrestataireFinalizationState> emit,
  ) async {
    emit(PrestataireFinalizationLoading());

    try {
      if (kDebugMode) {
        debugPrint('finalization submit keys=${event.formData.keys.toList()}');
      }

      // 1. Vérifier les documents obligatoires
      final requiredDocs = _validateRequiredDocuments(event.formData);
      if (!requiredDocs['isValid']) {
        emit(PrestataireFinalizationFailure(
            error:
                "Documents obligatoires manquants: ${requiredDocs['missing'].join(', ')}"));
        return;
      }

      // 2. Upload des documents
      final authToken = event.formData['authToken'] as String?;
      final uploadResults = await _uploadAllDocuments(event.formData, authToken);

      // 3. Mettre à jour le prestataire
      final updateResult = await _updatePrestataireStatus(
        event.formData['prestataireId'],
        uploadResults,
        event.formData,
        event.formData['authToken'] as String?,
      );

      if (updateResult['success']) {
        emit(PrestataireFinalizationSuccess(
            message:
                "✅ Profil finalisé avec succès ! Votre compte est en cours de validation."));
      } else {
        emit(PrestataireFinalizationFailure(error: updateResult['error']));
      }
    } catch (e) {
      print("❌ Erreur finalisation: $e");
      emit(PrestataireFinalizationFailure(
          error: "Erreur lors de la finalisation: $e"));
    }
  }

  // 🎯 UPLOAD D'UN DOCUMENT
  Future<void> _onUploadDocument(
    UploadDocumentEvent event,
    Emitter<PrestataireFinalizationState> emit,
  ) async {
    final prev = _lastDossier;
    if (prev != null) {
      final uploading = Set<String>.from(prev.uploadingFields)
        ..add(event.documentType);
      final pending = Map<String, String>.from(prev.pendingLocalFiles)
        ..[event.documentType] = event.file.path;
      _lastDossier = prev.copyWith(
        uploadingFields: uploading,
        pendingLocalFiles: pending,
      );
      emit(_lastDossier!);
    }

    try {
      final uploadResult = await _uploadSingleDocument(
        event.file,
        event.documentType,
        event.prestataireId,
        event.authToken,
      );

      if (uploadResult['success']) {
        final dossier = await _fetchDossier(
          event.prestataireId,
          event.authToken,
          pendingLocal: const {},
          uploading: const {},
        );
        _lastDossier = dossier;
        emit(dossier);
        emit(DocumentUploadSuccess(
          documentType: event.documentType,
          url: '',
        ));
      } else {
        emit(DocumentUploadFailure(
          documentType: event.documentType,
          error: uploadResult['error'],
        ));
        if (prev != null) {
          final dossier = await _fetchDossier(
            event.prestataireId,
            event.authToken,
          );
          _lastDossier = dossier;
          emit(dossier);
        }
      }
    } catch (e) {
      emit(DocumentUploadFailure(
        documentType: event.documentType,
        error: "Erreur upload: $e",
      ));
    }
  }

  Future<void> _onFinalizeDossier(
    FinalizeDossierEvent event,
    Emitter<PrestataireFinalizationState> emit,
  ) async {
    emit(PrestataireFinalizationLoading());
    try {
      final body = <String, dynamic>{};
      if (event.locationMaps != null) {
        body['localisationmaps'] = event.locationMaps;
      }
      if (event.locationLabel != null && event.locationLabel!.isNotEmpty) {
        body['localisation'] = event.locationLabel;
      }

      final response = await ApiClient().put(
        '/prestataire/${event.prestataireId}/finalize',
        body: body,
        token: event.authToken,
      );

      if (response.statusCode == 200) {
        emit(const PrestataireFinalizationSuccess(
          message:
              'Dossier envoyé. La vérification par l’équipe est distincte du statut « Fourni ».',
        ));
      } else {
        String message = 'Impossible de finaliser le dossier';
        try {
          final data = ApiClient.decodeJson(response);
          if (data is Map && (data['error'] != null)) {
            message = data['error'].toString();
          }
        } catch (_) {}
        emit(PrestataireFinalizationFailure(error: message));
        final dossier = await _fetchDossier(
          event.prestataireId,
          event.authToken,
        );
        _lastDossier = dossier;
        emit(dossier);
      }
    } catch (e) {
      emit(PrestataireFinalizationFailure(error: '$e'));
    }
  }

  // 🎯 VALIDATION — seule la localisation est obligatoire
  // CNI + selfie = optionnels (badge "Identité vérifiée")
  Map<String, dynamic> _validateRequiredDocuments(
      Map<String, dynamic> formData) {
    final missing = <String>[];

    if (formData['location'] == null) missing.add('Localisation');

    return {
      'isValid': missing.isEmpty,
      'missing': missing,
    };
  }

  // 🎯 UPLOAD DE TOUS LES DOCUMENTS
  Future<Map<String, dynamic>> _uploadAllDocuments(
      Map<String, dynamic> formData, String? authToken) async {
    final results = <String, String>{};

    try {
      // Upload CNI Recto
      if (formData['cniRecto'] != null) {
        final result = await _uploadSingleDocument(
          formData['cniRecto'],
          'cni_recto',
          formData['prestataireId'],
          authToken,
        );
        if (result['success']) results['cniRecto'] = result['url'];
      }

      // Upload CNI Verso
      if (formData['cniVerso'] != null) {
        final result = await _uploadSingleDocument(
          formData['cniVerso'],
          'cni_verso',
          formData['prestataireId'],
          authToken,
        );
        if (result['success']) results['cniVerso'] = result['url'];
      }

      // Upload Selfie
      if (formData['selfie'] != null) {
        final result = await _uploadSingleDocument(
          formData['selfie'],
          'selfie',
          formData['prestataireId'],
          authToken,
        );
        if (result['success']) results['selfie'] = result['url'];
      }

      // Upload Certificats (multiple)
      if (formData['certificates'] != null &&
          (formData['certificates'] as List).isNotEmpty) {
        final certificates = <String>[];
        for (int i = 0; i < (formData['certificates'] as List).length; i++) {
          final result = await _uploadSingleDocument(
            (formData['certificates'] as List)[i],
            'certificate_$i',
            formData['prestataireId'],
            authToken,
          );
          if (result['success']) certificates.add(result['url']);
        }
        if (certificates.isNotEmpty)
          results['certificates'] = certificates.join(',');
      }

      // Upload Assurance
      if (formData['insurance'] != null) {
        final result = await _uploadSingleDocument(
          formData['insurance'],
          'insurance',
          formData['prestataireId'],
          authToken,
        );
        if (result['success']) results['insurance'] = result['url'];
      }

      // Upload Portfolio (multiple)
      if (formData['portfolio'] != null &&
          (formData['portfolio'] as List).isNotEmpty) {
        final portfolio = <String>[];
        for (int i = 0; i < (formData['portfolio'] as List).length; i++) {
          final result = await _uploadSingleDocument(
            (formData['portfolio'] as List)[i],
            'portfolio_$i',
            formData['prestataireId'],
            authToken,
          );
          if (result['success']) portfolio.add(result['url']);
        }
        if (portfolio.isNotEmpty) results['portfolio'] = portfolio.join(',');
      }

      return {
        'success': true,
        'results': results,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur upload documents: $e',
      };
    }
  }

  // 🎯 UPLOAD D'UN DOCUMENT UNIQUE
  Future<Map<String, dynamic>> _uploadSingleDocument(
    File file,
    String documentType,
    String prestataireId,
    String? authToken,
  ) async {
    try {
      final api = ApiClient();
      final response = await api.sendAuthorizedMultipart(
        (access) async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${api.apiUrl}/upload/document'),
          );
          if (access != null && access.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $access';
          }
          request.fields['prestataireId'] = prestataireId;
          request.fields['documentType'] = documentType;
          request.files.add(await http.MultipartFile.fromPath(
            'document',
            file.path,
            filename:
                '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
          return request;
        },
        token: authToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur upload: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur upload: $e',
      };
    }
  }

  // 🎯 MISE À JOUR DU STATUT DU PRESTATAIRE
  Future<Map<String, dynamic>> _updatePrestataireStatus(
    String prestataireId,
    Map<String, dynamic> uploadResults,
    Map<String, dynamic> formData,
    String? authToken,
  ) async {
    try {
      final updateData = {
        'cni1': uploadResults['results']['cniRecto'],
        'cni2': uploadResults['results']['cniVerso'],
        'selfie': uploadResults['results']['selfie'],
        'diplomeCertificat':
            uploadResults['results']['certificates']?.split(',') ?? [],
        'attestationAssurance': uploadResults['results']['insurance'],
        'localisation': formData['address'],
        'localisationmaps': formData['location'],
      };

      final response = await ApiClient().put(
        '/prestataire/$prestataireId/finalize',
        body: updateData,
        token: authToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur mise à jour: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur mise à jour: $e',
      };
    }
  }
}
