import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';

class TwoFactorSetupScreenM extends StatefulWidget {
  const TwoFactorSetupScreenM({Key? key}) : super(key: key);

  @override
  State<TwoFactorSetupScreenM> createState() => _TwoFactorSetupScreenMState();
}

class _TwoFactorSetupScreenMState extends State<TwoFactorSetupScreenM> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isVerifying = false;
  bool _isDisabling = false;

  @override
  void initState() {
    super.initState();
    // Charger l'état actuel de l'authentification à deux facteurs
    context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SecurityPageBlocM(
        apiClient: ApiClient(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authentification à deux facteurs'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<SecurityPageBlocM, SecurityPageStateM>(
          listener: (context, state) {
            if (state is SecurityPageErrorStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SecurityPageSuccessStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is TwoFactorVerificationStateM) {
              if (state.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is SecurityPageLoadingStateM) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.teal),
                              const SizedBox(width: 8),
                              const Text(
                                'Authentification à deux facteurs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez une couche de sécurité supplémentaire à votre compte en activant l\'authentification à deux facteurs.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // État actuel
                  if (state is SecurityPageLoadedStateM) ...[
                    _buildCurrentStatus(state.twoFactorEnabled),

                    const SizedBox(height: 16),

                    // Configuration
                    if (!state.twoFactorEnabled) ...[
                      _buildSetupSection(),
                    ] else ...[
                      _buildDisableSection(),
                    ],
                  ],

                  // QR Code et instructions
                  if (state is TwoFactorEnabledStateM) ...[
                    _buildQRCodeSection(state),
                  ],

                  // Section de vérification
                  if (state is TwoFactorEnabledStateM) ...[
                    _buildVerificationSection(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(bool isEnabled) {
    return Card(
      color: isEnabled ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isEnabled ? Icons.check_circle : Icons.warning,
              color: isEnabled ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnabled
                        ? 'Authentification activée'
                        : 'Authentification désactivée',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.green : Colors.orange,
                    ),
                  ),
                  Text(
                    isEnabled
                        ? 'Votre compte est protégé par l\'authentification à deux facteurs.'
                        : 'Activez l\'authentification à deux facteurs pour sécuriser votre compte.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activer l\'authentification à deux facteurs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'authentification à deux facteurs ajoute une couche de sécurité supplémentaire à votre compte.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<SecurityPageBlocM>()
                      .add(EnableTwoFactorEventM());
                },
                icon: const Icon(Icons.phone_android),
                label:
                    const Text('Activer l\'authentification à deux facteurs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisableSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Désactiver l\'authentification à deux facteurs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Attention : Désactiver l\'authentification à deux facteurs réduit la sécurité de votre compte.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDisabling ? null : _disableTwoFactor,
                icon: _isDisabling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel),
                label: Text(_isDisabling ? 'Désactivation...' : 'Désactiver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(TwoFactorEnabledStateM state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanner le QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez votre application d\'authentification pour scanner ce QR code :',
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 100,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code généré',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scannez avec votre application d\'authentification',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('1. Ouvrez votre application d\'authentification'),
                  const Text('2. Scannez le QR code ci-dessus'),
                  const Text(
                      '3. Entrez le code généré dans le champ ci-dessous'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez le code à 6 chiffres généré par votre application d\'authentification :',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code de vérification',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
                hintText: '123456',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verifyCode,
                icon: _isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isVerifying ? 'Vérification...' : 'Vérifier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyCode() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un code à 6 chiffres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    context.read<SecurityPageBlocM>().add(
          VerifyTwoFactorCodeEventM(code: _codeController.text),
        );

    // Réinitialiser l'état après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    });
  }

  void _disableTwoFactor() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre mot de passe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDisabling = true;
    });

    context.read<SecurityPageBlocM>().add(
          DisableTwoFactorEventM(currentPassword: _passwordController.text),
        );

    // Réinitialiser l'état après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isDisabling = false;
        });
      }
    });
  }
}
