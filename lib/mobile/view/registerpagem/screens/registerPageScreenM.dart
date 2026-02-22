import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/services/authCubit.dart';
import '../registerpageblocm/registerPageBlocM.dart';
import '../registerpageblocm/registerPageEventM.dart';
import '../registerpageblocm/registerPageStateM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class RegisterPageScreenM extends StatefulWidget {
  const RegisterPageScreenM({super.key});

  @override
  State<RegisterPageScreenM> createState() => _RegisterPageScreenMState();
}

class _RegisterPageScreenMState extends State<RegisterPageScreenM>
    with SingleTickerProviderStateMixin {
  bool agreeToTerms = false;
  bool obscurePassword = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDAppBar(
        title: '',
        useGradient: false,
        backgroundColor: SDColors.white,
        centerTitle: false,
      ),
      body: BlocConsumer<RegisterPageBlocM, RegisterPageStateM>(
        listener: (context, state) {
          if (state.isSuccess) {
            if (state.utilisateur != null && state.token != null) {
              context.read<AuthCubit>().setAuthenticated(
                token: state.token!,
                utilisateur: state.utilisateur!,
                roles: [state.utilisateur!.role],
                activeRole: state.utilisateur!.role,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Inscription réussie ✅ Vous êtes maintenant connecté !",
                    style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
                  ),
                  backgroundColor: SDColors.success500,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Inscription réussie ✅")),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.push("/homepage");
            });
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage!,
                  style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
                ),
                backgroundColor: SDColors.error500,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SDSpacing.verticalSmallGap,
                  Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return ScaleTransition(
                          scale: Tween<double>(
                            begin: 1.0,
                            end: 1.1,
                          ).animate(_animationController),
                          child: child,
                        );
                      },
                      child: Image.asset('assets/logo1.png', height: 100),
                    ),
                  ),
                  SDSpacing.verticalLargeGap,
                  Text(
                    "Créer un compte",
                    textAlign: TextAlign.center,
                    style: SDTypography.displayMedium.copyWith(
                      color: SDColors.neutral900,
                    ),
                  ),
                  SDSpacing.verticalTinyGap,
                  Text(
                    "Rejoignez Soutrali Deals pour commencer",
                    textAlign: TextAlign.center,
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  SDSpacing.verticalLargeGap,

                  // Design System Form
                  SDInput(
                    label: "Nom complet",
                    hint: "Entrez votre nom complet",
                    prefixIcon: Icons.person_outline,
                    onChanged: (v) => context.read<RegisterPageBlocM>().add(
                      RegisterFullNameChanged(v),
                    ),
                  ),
                  SDSpacing.verticalDefaultGap,
                  SDInput(
                    label: "Numéro de Téléphone",
                    hint: "Ex: 0102030405",
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android,
                    onChanged: (v) => context.read<RegisterPageBlocM>().add(
                      RegisterPhoneChanged(v),
                    ),
                  ),
                  SDSpacing.verticalDefaultGap,
                  SDInput(
                    label: "Mot de passe",
                    hint: "Créez un mot de passe",
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    onChanged: (v) => context.read<RegisterPageBlocM>().add(
                      RegisterPasswordChanged(v),
                    ),
                  ),
                  SDSpacing.verticalDefaultGap,
                  SDInput(
                    label: "Confirmez le mot de passe",
                    hint: "Répétez le mot de passe",
                    obscureText: true,
                    prefixIcon: Icons.lock_reset,
                    onChanged: (v) => context.read<RegisterPageBlocM>().add(
                      RegisterConfirmPasswordChanged(v),
                    ),
                  ),

                  SDSpacing.verticalSmallGap,
                  Row(
                    children: [
                      Checkbox(
                        value: agreeToTerms,
                        activeColor: SDColors.primary600,
                        onChanged: (value) {
                          setState(() {
                            agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "J'accepte les termes et conditions",
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SDSpacing.verticalMediumGap,

                  SDButton(
                    text: "CRÉER MON COMPTE",
                    fullWidth: true,
                    isLoading: state.isSubmitting,
                    onPressed: agreeToTerms && !state.isSubmitting
                        ? () {
                      context.read<RegisterPageBlocM>().add(
                        RegisterSubmitted(),
                      );
                    }
                        : null,
                  ),

                  SDSpacing.verticalMediumGap,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Vous avez déjà un compte ?',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go("/login");
                        },
                        child: Text(
                          'Connectez-vous',
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.primary600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SDSpacing.verticalSmallGap,
                  Padding(
                    padding: EdgeInsets.only(bottom: SDSpacing.md),
                    child: Text(
                      "En vous inscrivant, vous acceptez nos conditions d'utilisation et notre politique de confidentialité.",
                      textAlign: TextAlign.center,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}