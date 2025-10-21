import 'package:equatable/equatable.dart';

/// 📁 Modèle pour un élément de portfolio
class PortfolioItem extends Equatable {
  final String title;
  final String description;
  final String imageUrl;
  final String projectUrl;

  const PortfolioItem({
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.projectUrl = '',
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      projectUrl: json['projectUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'projectUrl': projectUrl,
    };
  }

  @override
  List<Object?> get props => [title, description, imageUrl, projectUrl];
}

/// 🔒 Modèle pour les documents de vérification
class VerificationDocuments extends Equatable {
  final String? cni1;
  final String? cni2;
  final String? selfie;
  final bool isVerified;

  const VerificationDocuments({
    this.cni1,
    this.cni2,
    this.selfie,
    this.isVerified = false,
  });

  factory VerificationDocuments.fromJson(Map<String, dynamic> json) {
    return VerificationDocuments(
      cni1: json['cni1'] as String?,
      cni2: json['cni2'] as String?,
      selfie: json['selfie'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cni1 != null) 'cni1': cni1,
      if (cni2 != null) 'cni2': cni2,
      if (selfie != null) 'selfie': selfie,
      'isVerified': isVerified,
    };
  }

  @override
  List<Object?> get props => [cni1, cni2, selfie, isVerified];
}

class FreelanceModel extends Equatable {
  final String id;
  final String name;
  final String job;
  final String category;
  final String imagePath;
  final double rating;
  final int completedJobs;
  final bool isTopRated;
  final bool isFeatured;
  final bool isNew;
  final List<String> skills;
  final double hourlyRate;
  final String description;
  final int responseTime; // temps de réponse en heures

  // ✅ NOUVEAUX CHAMPS
  final String experienceLevel; // Débutant, Intermédiaire, Expert
  final String availabilityStatus; // Disponible, Occupé, En pause
  final String workingHours; // Temps plein, Temps partiel, Ponctuel
  final String location;
  final String? phoneNumber;
  final List<PortfolioItem> portfolioItems;
  final VerificationDocuments? verificationDocuments;
  final double totalEarnings;
  final int currentProjects;
  final double clientSatisfaction; // 0-100%
  final List<String> preferredCategories;
  final String accountStatus; // Active, Suspended, Pending

  const FreelanceModel({
    required this.id,
    required this.name,
    required this.job,
    required this.category,
    required this.imagePath,
    this.rating = 0.0,
    this.completedJobs = 0,
    this.isTopRated = false,
    this.isFeatured = false,
    this.isNew = false,
    this.skills = const [],
    this.hourlyRate = 0.0,
    this.description = '',
    this.responseTime = 24,
    // Nouveaux champs
    this.experienceLevel = 'Débutant',
    this.availabilityStatus = 'Disponible',
    this.workingHours = 'Temps partiel',
    this.location = '',
    this.phoneNumber,
    this.portfolioItems = const [],
    this.verificationDocuments,
    this.totalEarnings = 0.0,
    this.currentProjects = 0,
    this.clientSatisfaction = 0.0,
    this.preferredCategories = const [],
    this.accountStatus = 'Active',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        job,
        category,
        imagePath,
        rating,
        completedJobs,
        isTopRated,
        isFeatured,
        isNew,
        skills,
        hourlyRate,
        description,
        responseTime,
        experienceLevel,
        availabilityStatus,
        workingHours,
        location,
        phoneNumber,
        portfolioItems,
        verificationDocuments,
        totalEarnings,
        currentProjects,
        clientSatisfaction,
        preferredCategories,
        accountStatus,
      ];

  // ✅ NOUVELLE FACTORY : Convertir depuis le backend (avec gestion robuste des nulls)
  factory FreelanceModel.fromBackend(Map<String, dynamic> json) {
    // 🛡️ Helper pour extraire string avec fallback
    String safeString(String key, String defaultValue) {
      final value = json[key];
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    // 🛡️ Helper pour extraire liste de strings
    List<String> safeStringList(String key) {
      final value = json[key];
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return FreelanceModel(
      id: safeString('_id', ''),
      name: safeString('name', 'Freelance'),
      job: safeString('job', 'Non spécifié'),
      category: safeString('category', 'Autre'),
      imagePath: safeString('imagePath', ''),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completedJobs'] as int? ?? 0,
      isTopRated: json['isTopRated'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? true,
      skills: safeStringList('skills'),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      description: safeString('description', 'Aucune description disponible'),
      responseTime: json['responseTime'] as int? ?? 24,
      // Nouveaux champs avec gestion robuste des nulls
      experienceLevel: safeString('experienceLevel', 'Débutant'),
      availabilityStatus: safeString('availabilityStatus', 'Disponible'),
      workingHours: safeString('workingHours', 'Temps partiel'),
      location: safeString('location', ''),
      phoneNumber: json['phoneNumber'] as String?,
      portfolioItems:
          json['portfolioItems'] != null && json['portfolioItems'] is List
              ? (json['portfolioItems'] as List)
                  .map((item) {
                    try {
                      if (item is Map<String, dynamic>) {
                        return PortfolioItem.fromJson(item);
                      }
                      return null;
                    } catch (e) {
                      print('⚠️ Erreur parsing portfolio item: $e');
                      return null;
                    }
                  })
                  .where((item) => item != null)
                  .cast<PortfolioItem>()
                  .toList()
              : [],
      verificationDocuments: json['verificationDocuments'] != null &&
              json['verificationDocuments'] is Map
          ? VerificationDocuments.fromJson(
              json['verificationDocuments'] as Map<String, dynamic>)
          : null,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      currentProjects: json['currentProjects'] as int? ?? 0,
      clientSatisfaction:
          (json['clientSatisfaction'] as num?)?.toDouble() ?? 0.0,
      preferredCategories: safeStringList('preferredCategories'),
      accountStatus: safeString('accountStatus', 'Active'),
    );
  }

  // Méthode factory pour créer une instance à partir d'un Map (JSON)
  factory FreelanceModel.fromJson(Map<String, dynamic> json) {
    return FreelanceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      job: json['job'] as String,
      category: json['category'] as String,
      imagePath: json['imagePath'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completedJobs'] as int? ?? 0,
      isTopRated: json['isTopRated'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      responseTime: json['responseTime'] as int? ?? 24,
    );
  }

  // Méthode pour convertir l'instance en Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'job': job,
      'category': category,
      'imagePath': imagePath,
      'rating': rating,
      'completedJobs': completedJobs,
      'isTopRated': isTopRated,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'skills': skills,
      'hourlyRate': hourlyRate,
      'description': description,
      'responseTime': responseTime,
      'experienceLevel': experienceLevel,
      'availabilityStatus': availabilityStatus,
      'workingHours': workingHours,
      'location': location,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'portfolioItems': portfolioItems.map((item) => item.toJson()).toList(),
      if (verificationDocuments != null)
        'verificationDocuments': verificationDocuments!.toJson(),
      'totalEarnings': totalEarnings,
      'currentProjects': currentProjects,
      'clientSatisfaction': clientSatisfaction,
      'preferredCategories': preferredCategories,
      'accountStatus': accountStatus,
    };
  }

  // Méthode pour créer une copie avec certains champs modifiés
  FreelanceModel copyWith({
    String? id,
    String? name,
    String? job,
    String? category,
    String? imagePath,
    double? rating,
    int? completedJobs,
    bool? isTopRated,
    bool? isFeatured,
    bool? isNew,
    List<String>? skills,
    double? hourlyRate,
    String? description,
    int? responseTime,
    String? experienceLevel,
    String? availabilityStatus,
    String? workingHours,
    String? location,
    String? phoneNumber,
    List<PortfolioItem>? portfolioItems,
    VerificationDocuments? verificationDocuments,
    double? totalEarnings,
    int? currentProjects,
    double? clientSatisfaction,
    List<String>? preferredCategories,
    String? accountStatus,
  }) {
    return FreelanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      job: job ?? this.job,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      isTopRated: isTopRated ?? this.isTopRated,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      skills: skills ?? this.skills,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      description: description ?? this.description,
      responseTime: responseTime ?? this.responseTime,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      workingHours: workingHours ?? this.workingHours,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      portfolioItems: portfolioItems ?? this.portfolioItems,
      verificationDocuments:
          verificationDocuments ?? this.verificationDocuments,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentProjects: currentProjects ?? this.currentProjects,
      clientSatisfaction: clientSatisfaction ?? this.clientSatisfaction,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}

// Données fictives pour les tests
List<FreelanceModel> getMockFreelancers() {
  return [
    const FreelanceModel(
      id: '1',
      name: 'Sali Diallo',
      job: 'Traductrice',
      category: 'Traduction',
      imagePath: 'assets/esty.jpg',
      rating: 4.8,
      completedJobs: 138,
      isTopRated: true,
      skills: ['Anglais', 'Français', 'Espagnol', 'Arabe'],
      hourlyRate: 25.0,
      description:
          'Traductrice professionnelle avec plus de 5 ans d\'expérience',
      responseTime: 2,
    ),
    const FreelanceModel(
      id: '2',
      name: 'Oumar Sy',
      job: 'Développeur',
      category: 'Dev',
      imagePath: 'assets/profile_picture.jpg',
      rating: 4.9,
      completedJobs: 256,
      isTopRated: true,
      isFeatured: true,
      skills: ['Flutter', 'React Native', 'Node.js', 'Python'],
      hourlyRate: 35.0,
      description: 'Développeur full-stack spécialisé en applications mobiles',
      responseTime: 1,
    ),
    const FreelanceModel(
      id: '3',
      name: 'Léa Touré',
      job: 'Community Manager',
      category: 'Marketing',
      imagePath: 'assets/coiffuer2.jpeg',
      rating: 4.7,
      completedJobs: 94,
      isNew: false,
      skills: ['Instagram', 'TikTok', 'Facebook Ads', 'Content Strategy'],
      hourlyRate: 28.0,
      description: 'Community Manager créative et orientée résultats',
      responseTime: 3,
    ),
    const FreelanceModel(
      id: '4',
      name: 'Ali Ndiaye',
      job: 'Designer UI/UX',
      category: 'Design',
      imagePath: 'assets/profile_picture.jpg',
      rating: 4.9,
      completedJobs: 189,
      isTopRated: true,
      isFeatured: true,
      skills: ['Figma', 'Adobe XD', 'Sketch', 'Prototypage'],
      hourlyRate: 40.0,
      description: 'Designer UI/UX avec approche centrée sur l\'utilisateur',
      responseTime: 4,
    ),
    const FreelanceModel(
      id: '5',
      name: 'Fatou Sow',
      job: 'Vidéaste',
      category: 'Vidéo',
      imagePath: 'assets/esty.jpg',
      rating: 4.6,
      completedJobs: 72,
      isNew: true,
      skills: [
        'Montage vidéo',
        'Motion Design',
        'After Effects',
        'Premiere Pro'
      ],
      hourlyRate: 30.0,
      description:
          'Vidéaste professionnelle spécialisée dans le marketing digital',
      responseTime: 6,
    ),
    const FreelanceModel(
      id: '6',
      name: 'Mamadou Diop',
      job: 'Rédacteur',
      category: 'Rédaction',
      imagePath: 'assets/profile_picture.jpg',
      rating: 4.5,
      completedJobs: 104,
      skills: ['SEO', 'Copywriting', 'Storytelling', 'Articles de blog'],
      hourlyRate: 22.0,
      description: 'Rédacteur web SEO avec expertise dans divers secteurs',
      responseTime: 5,
    ),
    const FreelanceModel(
      id: '7',
      name: 'Aminata Ba',
      job: 'Photographe',
      category: 'Photo',
      imagePath: 'assets/esty.jpg',
      rating: 4.7,
      completedJobs: 158,
      isTopRated: true,
      skills: ['Portrait', 'Produit', 'Événementiel', 'Retouche photo'],
      hourlyRate: 45.0,
      description:
          'Photographe professionnelle, spécialisation en photo commerciale',
      responseTime: 8,
    ),
  ];
}
