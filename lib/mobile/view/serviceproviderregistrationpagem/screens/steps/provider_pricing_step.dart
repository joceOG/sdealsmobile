import 'package:flutter/material.dart';

class ProviderPricingStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderPricingStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ProviderPricingStep> createState() => _ProviderPricingStepState();
}

class _ProviderPricingStepState extends State<ProviderPricingStep> {
  final TextEditingController _dailyRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }

  void _initializeFormValues() {
    _dailyRateController.text = widget.formData['dailyRate']?.toString() ?? '';
    _descriptionController.text = widget.formData['description'] ?? '';
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateFormData() {
    Map<String, dynamic> updatedData = {
      'dailyRate': double.tryParse(_dailyRateController.text) ?? 0.0,
      'description': _descriptionController.text,
    };

    widget.onDataChanged(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Définissez votre tarif pour une journée de travail',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Tarif par jour
          TextFormField(
            controller: _dailyRateController,
            decoration: const InputDecoration(
              labelText: 'Tarif par jour (FCFA) *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.monetization_on),
              hintText: 'Ex: 15000',
              suffixText: 'FCFA',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre tarif par jour';
              }
              final rate = double.tryParse(value);
              if (rate == null || rate <= 0) {
                return 'Veuillez entrer un montant valide';
              }
              return null;
            },
            onChanged: (value) => _updateFormData(),
          ),
          const SizedBox(height: 16),

          // Description (optionnelle)
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description de vos services (optionnelle)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Décrivez brièvement ce que vous faites...',
            ),
            maxLines: 3,
            onChanged: (value) => _updateFormData(),
          ),
          const SizedBox(height: 20),

          // Exemples de tarifs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Exemples de tarifs par jour',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• Plombier : 15,000 - 25,000 FCFA'),
                const Text('• Électricien : 20,000 - 30,000 FCFA'),
                const Text('• Peintre : 10,000 - 20,000 FCFA'),
                const Text('• Menuisier : 25,000 - 40,000 FCFA'),
                const SizedBox(height: 8),
                const Text(
                  'Vous pourrez ajuster vos tarifs plus tard dans votre profil.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Note finale
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parfait ! Votre profil prestataire est créé. Vous pouvez maintenant recevoir des demandes de clients.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
