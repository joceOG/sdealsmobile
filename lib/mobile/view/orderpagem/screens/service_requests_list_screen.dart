import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import '../servicerequestcubit/service_request_cubit.dart';
import 'service_request_summary_screen.dart';
import '../../common/widgets/unauthenticated_banner.dart';

class ServiceRequestsListScreen extends StatelessWidget {
  const ServiceRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        appBarTitle: 'Mes demandes',
        icon: Icons.assignment_outlined,
        title: 'Vos demandes de service',
        description: 'Connectez-vous pour consulter et suivre toutes vos demandes de prestations en cours.',
      );
    }
    return BlocProvider(
      create: (_) => ServiceRequestCubit()
        ..fetchMine(
            token: auth.token, utilisateurId: auth.utilisateur.idutilisateur),
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDAppBarIconThemed(
          style: SDAppBarIconStyles.onLightSurface,
          bar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: SDColors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: SDColors.neutral900,
          title: Text(
            'Mes demandes',
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: SDColors.neutral200),
          ),
        ),
        ),
        body: BlocBuilder<ServiceRequestCubit, ServiceRequestState>(
          builder: (context, state) {
            if (state is ServiceRequestLoading ||
                state is ServiceRequestInitial) {
              return Center(
                  child: CircularProgressIndicator(
                      color: SDColors.primary600));
            } else if (state is ServiceRequestError) {
              return Center(child: Text(state.message));
            } else if (state is ServiceRequestListLoaded) {
              final items = state.items;
              if (items.isEmpty) {
                return const Center(
                    child: Text('Aucune demande pour le moment.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final it = items[index];
                  final status = it['status']?.toString() ?? 'PENDING';
                  final adresse = it['adresse']?.toString() ?? '';
                  final ville = it['ville']?.toString() ?? '';
                  return ListTile(
                    leading: Icon(Icons.work_outline,
                        color: status == 'DONE' ? Colors.green : Colors.grey),
                    title: Text('Statut: $status'),
                    subtitle: Text([adresse, ville]
                        .where((e) => e.isNotEmpty)
                        .join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final id = it['_id']?.toString();
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceRequestSummaryScreen(
                                requestId: id, token: auth.token),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
