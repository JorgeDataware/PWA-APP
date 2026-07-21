import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/wear_pin_provider.dart';

class WearablePinScreen extends StatefulWidget {
  const WearablePinScreen({super.key});

  @override
  State<WearablePinScreen> createState() => _WearablePinScreenState();
}

class _WearablePinScreenState extends State<WearablePinScreen> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _message;
  bool _submitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit(WearPinProvider pin) async {
    final value = _pinController.text;
    setState(() => _message = null);
    if (value.length != 6) {
      setState(() => _message = 'Ingresa los seis dígitos.');
      return;
    }
    if (pin.needsSetup && value != _confirmationController.text) {
      setState(() => _message = 'Los PIN no coinciden.');
      return;
    }

    setState(() => _submitting = true);
    try {
      if (pin.needsSetup) {
        await pin.setPin(value);
      } else {
        final result = await pin.unlock(value);
        if (!result.isValid) {
          final lock = result.lockedUntil;
          setState(() {
            _message = lock == null
                ? 'PIN incorrecto. Quedan ${result.remainingAttempts} intentos.'
                : 'Demasiados intentos. Intenta de nuevo en 30 segundos.';
          });
          _pinController.clear();
          return;
        }
      }
      if (mounted) context.go('/news');
    } on ArgumentError catch (error) {
      setState(() => _message = error.message.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = context.watch<WearPinProvider>();
    final setup = pin.needsSetup;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: AppTheme.primary, size: 34),
                const SizedBox(height: 10),
                Text(
                  setup ? 'Protege tu reloj' : 'Desbloquear',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  setup ? 'Crea un PIN de seis dígitos.' : 'Ingresa tu PIN de seis dígitos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _PinField(controller: _pinController, label: 'PIN'),
                if (setup) ...[
                  const SizedBox(height: 8),
                  _PinField(controller: _confirmationController, label: 'Confirmar'),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.error, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(pin),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(132, 40)),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(setup ? 'Guardar PIN' : 'Desbloquear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PinField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: label == 'PIN',
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 6),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: AppTheme.cardBg,
      ),
    );
  }
}
