import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/data/models/commande_model.dart';
import '../../../../data/services/websocket_service.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/api_client.dart';
import 'commande_event.dart';
import 'commande_state.dart';
// NOTE: imports non utilisés pour le flux e-commerce actuel; le flux Prestation
// utilisera un Cubit dédié dans un fichier séparé.

class CommandeBloc extends Bloc<CommandeEvent, CommandeState> {
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  final ApiClient _apiClient = ApiClient();

  CommandeBloc() : super(CommandeState.initial()) {
    on<ChargerCommandes>(_onChargerCommandes);
    on<FiltrerParStatus>(_onFiltrerParStatus);
    on<AjouterCommande>(_onAjouterCommande);
    on<MettreAJourCommande>(_onMettreAJourCommande);
    on<NoterCommande>(_onNoterCommande);
    on<RechercherCommandes>(_onRechercherCommandes);
    on<AnnulerCommande>(_onAnnulerCommande);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<OrderStatusUpdated>(_onOrderStatusUpdated);
    on<SendPushNotification>(_onSendPushNotification);
    on<NotificationReceived>(_onNotificationReceived);

    // Configuration des callbacks WebSocket
    _setupWebSocketCallbacks();
  }

  Future<void> _onChargerCommandes(
    ChargerCommandes event,
    Emitter<CommandeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // 🔄 Appel API backend
      print('📡 Chargement commandes depuis API...');
      
      final commandesData = await _apiClient.getCommandes(
        limit: 50, // Charger 50 commandes max
      );

      // Convertir les data backend en CommandeModel
      final commandes = commandesData
          .map((data) => CommandeModel.fromBackend(data))
          .toList();

      print('✅ ${commandes.length} commandes chargées depuis API');

      emit(state.copyWith(
        isLoading: false,
        commandes: commandes,
        error: null,
      ));
    } catch (error) {
      print('⚠️ Erreur API commandes: $error');
      emit(state.copyWith(
        isLoading: false,
        commandes: const [],
        error: 'Impossible de charger les commandes',
      ));
    }
  }

  void _onFiltrerParStatus(
    FiltrerParStatus event,
    Emitter<CommandeState> emit,
  ) {
    emit(state.copyWith(filtreStatus: event.status));
  }

  void _onAjouterCommande(
    AjouterCommande event,
    Emitter<CommandeState> emit,
  ) {
    final updatedCommandes = [...state.commandes, event.commande];
    emit(state.copyWith(commandes: updatedCommandes));
  }

  void _onMettreAJourCommande(
    MettreAJourCommande event,
    Emitter<CommandeState> emit,
  ) {
    final updatedCommandes = state.commandes.map((commande) {
      if (commande.id == event.commande.id) {
        return event.commande;
      }
      return commande;
    }).toList();

    emit(state.copyWith(commandes: updatedCommandes));
  }

  void _onNoterCommande(
    NoterCommande event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      // 📡 Envoyer la note au backend
      print('📡 Envoi notation pour commande ${event.commandeId}');
      
      await _apiClient.updateCommande(
        commandeId: event.commandeId,
        updates: {
          'note': event.note,
          'commentaire': event.commentaire,
          'estNotee': true,
        },
      );

      print('✅ Notation envoyée avec succès');

      // Mettre à jour localement
      final updatedCommandes = state.commandes.map((commande) {
        if (commande.id == event.commandeId) {
          return commande.copyWith(
            estNotee: true,
            note: event.note,
            commentaire: event.commentaire,
          );
        }
        return commande;
      }).toList();

      emit(state.copyWith(commandes: updatedCommandes, error: null));
    } catch (error) {
      print('❌ Erreur notation: $error');
      emit(state.copyWith(
        error: 'Impossible d\'envoyer la note',
      ));
    }
  }

  void _onRechercherCommandes(
    RechercherCommandes event,
    Emitter<CommandeState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onAnnulerCommande(
    AnnulerCommande event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      // 📡 Annuler via API
      print('📡 Annulation commande ${event.commandeId}');
      
      final success = await _apiClient.cancelCommande(event.commandeId);
      
      if (success) {
        print('✅ Commande annulée avec succès');
        
        // Mettre à jour localement
        final updatedCommandes = state.commandes.map((commande) {
          if (commande.id == event.commandeId) {
            return commande.copyWith(status: CommandeStatus.annulee);
          }
          return commande;
        }).toList();

        emit(state.copyWith(commandes: updatedCommandes, error: null));
      } else {
        emit(state.copyWith(error: 'Échec annulation'));
      }
    } catch (error) {
      print('❌ Erreur annulation: $error');
      emit(state.copyWith(error: 'Impossible d\'annuler'));
    }
  }

  // 🔌 CONFIGURATION DES CALLBACKS WEBSOCKET
  void _setupWebSocketCallbacks() {
    _webSocketService.onOrderStatusUpdated((data) {
      add(OrderStatusUpdated(data));
    });

    _webSocketService.onOrderUpdate((data) {
      print('📦 Mise à jour commande reçue: $data');
    });

    _webSocketService.onOrderError((error) {
      print('❌ Erreur commande WebSocket: $error');
    });
  }

  // 🔌 CONNEXION WEBSOCKET
  Future<void> _onConnectWebSocket(
    ConnectWebSocket event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      await _webSocketService.connect();
      emit(state.copyWith(isWebSocketConnected: true));
    } catch (error) {
      emit(state.copyWith(
        isWebSocketConnected: false,
        error: 'Erreur connexion WebSocket: $error',
      ));
    }
  }

  // 🔌 DÉCONNEXION WEBSOCKET
  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<CommandeState> emit,
  ) async {
    _webSocketService.disconnect();
    emit(state.copyWith(isWebSocketConnected: false));
  }

  // 📦 MISE À JOUR STATUT COMMANDE VIA WEBSOCKET
  Future<void> _onOrderStatusUpdated(
    OrderStatusUpdated event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      final orderData = event.orderData;
      final orderId = orderData['orderId']?.toString() ?? '';
      final newStatus = orderData['status']?.toString() ?? '';

      // Mettre à jour la commande dans la liste
      final updatedCommandes = state.commandes.map((commande) {
        if (commande.id == orderId) {
          return commande.copyWith(
            status: _parseCommandeStatus(newStatus),
          );
        }
        return commande;
      }).toList();

      emit(state.copyWith(
        commandes: updatedCommandes,
        lastUpdate: DateTime.now(),
      ));

      print('📦 Commande $orderId mise à jour: $newStatus');
    } catch (error) {
      print('❌ Erreur mise à jour statut commande: $error');
    }
  }

  // 🔄 PARSER LE STATUT DE LA COMMANDE
  CommandeStatus _parseCommandeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return CommandeStatus.enCours;
      case 'en attente':
        return CommandeStatus.enAttente;
      case 'terminée':
        return CommandeStatus.terminee;
      case 'annulée':
        return CommandeStatus.annulee;
      default:
        return CommandeStatus.enCours;
    }
  }

  // 🔔 ENVOYER NOTIFICATION PUSH
  Future<void> _onSendPushNotification(
    SendPushNotification event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      final success = await _notificationService.sendPushNotification(
        userId: event.userId,
        title: event.title,
        message: event.message,
        data: event.data,
      );

      if (success) {
        print('✅ Notification envoyée avec succès');
      } else {
        print('❌ Échec envoi notification');
        emit(state.copyWith(
          error: 'Erreur envoi notification',
        ));
      }
    } catch (error) {
      print('❌ Erreur envoi notification: $error');
      emit(state.copyWith(
        error: 'Erreur envoi notification: $error',
      ));
    }
  }

  // 🔔 NOTIFICATION REÇUE
  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<CommandeState> emit,
  ) async {
    try {
      final notificationData = event.notificationData;
      final type = notificationData['type']?.toString() ?? '';

      print('🔔 Notification reçue: $type');

      // Traiter selon le type de notification
      switch (type) {
        case 'order_status':
          _handleOrderStatusNotification(notificationData, emit);
          break;
        case 'payment_received':
          _handlePaymentNotification(notificationData, emit);
          break;
        case 'delivery_update':
          _handleDeliveryNotification(notificationData, emit);
          break;
        default:
          print('📱 Notification générique: $notificationData');
      }
    } catch (error) {
      print('❌ Erreur traitement notification: $error');
    }
  }

  // 📦 TRAITER NOTIFICATION STATUT COMMANDE
  void _handleOrderStatusNotification(
    Map<String, dynamic> data,
    Emitter<CommandeState> emit,
  ) {
    final orderId = data['orderId']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';

    // Mettre à jour la commande
    final updatedCommandes = state.commandes.map((commande) {
      if (commande.id == orderId) {
        return commande.copyWith(
          status: _parseCommandeStatus(status),
        );
      }
      return commande;
    }).toList();

    emit(state.copyWith(
      commandes: updatedCommandes,
      lastUpdate: DateTime.now(),
    ));

    print('📦 Commande $orderId mise à jour via notification: $status');
  }

  // 💰 TRAITER NOTIFICATION PAIEMENT
  void _handlePaymentNotification(
    Map<String, dynamic> data,
    Emitter<CommandeState> emit,
  ) {
    final orderId = data['orderId']?.toString() ?? '';
    final amount = data['amount']?.toDouble() ?? 0.0;

    print('💰 Paiement reçu pour commande $orderId: $amount FCFA');

    // Mettre à jour la commande avec le statut payé
    final updatedCommandes = state.commandes.map((commande) {
      if (commande.id == orderId) {
        return commande.copyWith(
          status: CommandeStatus.terminee,
        );
      }
      return commande;
    }).toList();

    emit(state.copyWith(
      commandes: updatedCommandes,
      lastUpdate: DateTime.now(),
    ));
  }

  // 🚚 TRAITER NOTIFICATION LIVRAISON
  void _handleDeliveryNotification(
    Map<String, dynamic> data,
    Emitter<CommandeState> emit,
  ) {
    final orderId = data['orderId']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';

    print('🚚 Mise à jour livraison pour commande $orderId: $status');

    // Mettre à jour la commande
    final updatedCommandes = state.commandes.map((commande) {
      if (commande.id == orderId) {
        return commande.copyWith(
          status: _parseCommandeStatus(status),
        );
      }
      return commande;
    }).toList();

    emit(state.copyWith(
      commandes: updatedCommandes,
      lastUpdate: DateTime.now(),
    ));
  }

  // 🧹 NETTOYAGE — ne pas disposer le WebSocket singleton global
  @override
  Future<void> close() {
    _notificationService.dispose();
    return super.close();
  }
}
