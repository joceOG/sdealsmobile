import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

class UploadDocumentEvent extends PrestataireFinalizationEvent {
  final String documentType;
  final File file;
  final String prestataireId;

  const UploadDocumentEvent({
    required this.documentType,
    required this.file,
    required this.prestataireId,
  });

  @override
  List<Object?> get props => [documentType, file, prestataireId];
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

// 🎯 BLOC
class PrestataireFinalizationBloc
    extends Bloc<PrestataireFinalizationEvent, PrestataireFinalizationState> {
  final String apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';

  PrestataireFinalizationBloc() : super(PrestataireFinalizationInitial()) {
    on<SubmitFinalizationEvent>(_onSubmitFinalization);
    on<UploadDocumentEvent>(_onUploadDocument);
  }

  // 🎯 SOUMISSION DE LA FINALISATION
  Future<void> _onSubmitFinalization(
    SubmitFinalizationEvent event,
    Emitter<PrestataireFinalizationState> emit,
  ) async {
    emit(PrestataireFinalizationLoading());

    try {
      print("🚀 Soumission finalisation: ${event.formData}");

      // 1. Vérifier les documents obligatoires
      final requiredDocs = _validateRequiredDocuments(event.formData);
      if (!requiredDocs['isValid']) {
        emit(PrestataireFinalizationFailure(
            error:
                "Documents obligatoires manquants: ${requiredDocs['missing'].join(', ')}"));
        return;
      }

      // 2. Upload des documents
      final uploadResults = await _uploadAllDocuments(event.formData);

      // 3. Mettre à jour le prestataire
      final updateResult = await _updatePrestataireStatus(
        event.formData['prestataireId'],
        uploadResults,
        event.formData,
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
    try {
      print("📤 Upload document: ${event.documentType}");

      final uploadResult = await _uploadSingleDocument(
        event.file,
        event.documentType,
        event.prestataireId,
      );

      if (uploadResult['success']) {
        emit(DocumentUploadSuccess(
          documentType: event.documentType,
          url: uploadResult['url'],
        ));
      } else {
        emit(DocumentUploadFailure(
          documentType: event.documentType,
          error: uploadResult['error'],
        ));
      }
    } catch (e) {
      emit(DocumentUploadFailure(
        documentType: event.documentType,
        error: "Erreur upload: $e",
      ));
    }
  }

  // 🎯 VALIDATION DES DOCUMENTS OBLIGATOIRES
  Map<String, dynamic> _validateRequiredDocuments(
      Map<String, dynamic> formData) {
    final missing = <String>[];

    if (formData['cniRecto'] == null) missing.add('CNI Recto');
    if (formData['cniVerso'] == null) missing.add('CNI Verso');
    if (formData['selfie'] == null) missing.add('Selfie');
    if (formData['location'] == null) missing.add('Localisation');

    return {
      'isValid': missing.isEmpty,
      'missing': missing,
    };
  }

  // 🎯 UPLOAD DE TOUS LES DOCUMENTS
  Future<Map<String, dynamic>> _uploadAllDocuments(
      Map<String, dynamic> formData) async {
    final results = <String, String>{};

    try {
      // Upload CNI Recto
      if (formData['cniRecto'] != null) {
        final result = await _uploadSingleDocument(
          formData['cniRecto'],
          'cni_recto',
          formData['prestataireId'],
        );
        if (result['success']) results['cniRecto'] = result['url'];
      }

      // Upload CNI Verso
      if (formData['cniVerso'] != null) {
        final result = await _uploadSingleDocument(
          formData['cniVerso'],
          'cni_verso',
          formData['prestataireId'],
        );
        if (result['success']) results['cniVerso'] = result['url'];
      }

      // Upload Selfie
      if (formData['selfie'] != null) {
        final result = await _uploadSingleDocument(
          formData['selfie'],
          'selfie',
          formData['prestataireId'],
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
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/upload/document'),
      );

      request.fields['prestataireId'] = prestataireId;
      request.fields['documentType'] = documentType;
      request.files.add(await http.MultipartFile.fromPath(
        'document',
        file.path,
        filename:
            '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
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
  ) async {
    try {
      final updateData = {
        'finalizationStatus': {
          'cniUploaded': uploadResults['results']['cniRecto'] != null &&
              uploadResults['results']['cniVerso'] != null,
          'selfieUploaded': uploadResults['results']['selfie'] != null,
          'locationSet': formData['location'] != null,
          'certificatesUploaded':
              uploadResults['results']['certificates'] != null,
          'insuranceUploaded': uploadResults['results']['insurance'] != null,
          'portfolioUploaded': uploadResults['results']['portfolio'] != null,
        },
        'cni1': uploadResults['results']['cniRecto'],
        'cni2': uploadResults['results']['cniVerso'],
        'selfie': uploadResults['results']['selfie'],
        'diplomeCertificat':
            uploadResults['results']['certificates']?.split(',') ?? [],
        'attestationAssurance': uploadResults['results']['insurance'],
        'localisation': formData['address'],
        'localisationmaps': formData['location'],
      };

      final response = await http.put(
        Uri.parse('$apiUrl/prestataire/$prestataireId/finalize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
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
